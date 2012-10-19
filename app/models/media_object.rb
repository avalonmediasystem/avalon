class MediaObject < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods
  include ActiveFedora::Relationships
  include Hydra::ModelMixins::RightsMetadata

  has_relationship "parts", :has_part

  has_metadata name: "DC", type: DublinCoreDocument
  has_metadata name: "descMetadata", type: ModsDocument	

  after_create :after_create
  
  # Before saving put the pieces into the right order and validate to make sure that
  # there are no syntactic errors
  before_save 'descMetadata.reorder_elements', prepend: true
  
  # Call custom validation methods to ensure that required fields are present and
  # that preferred controlled vocabulary standards are used
  validate :minimally_complete_record
  
  delegate :avalon_uploader, to: :DC, at: [:creator], unique: true
  delegate :avalon_publisher, to: :DC, at: [:publisher], unique: true
  # Delegate variables to expose them for the forms
  delegate :title, to: :descMetadata, at: [:main_title], unique: true
  delegate :creator, to: :descMetadata, at: [:creator_name], unique: true
  delegate :created_on, to: :descMetadata, at: [:creation_date], unique: true
  delegate :abstract, to: :descMetadata, at: [:summary], unique: true
  delegate :format, to: :descMetadata, at: [:media_type], unique: true
  # Additional descriptive metadata
  delegate :contributor, to: :descMetadata, at: [:contributor_name]
  delegate :publisher, to: :descMetadata, at: [:publisher_name]
  delegate :genre, to: :descMetadata, at: [:genre], unique: true
  delegate :subject, to: :descMetadata, at: [:topical_subject]
  delegate :relatedItem, to: :descMetadata, at: [:related_item_id]
  # Temporal and spatial coverage are a bit tricky but this should work
  delegate :spatial, to: :descMetadata, at: [:geographic_subject]
  delegate :temporal, to: :descMetadata, at: [:temporal_subject]
  
  accepts_nested_attributes_for :parts, :allow_destroy => true
  
  # Stub method to determine if the record is done or not. This should be based on
  # whether the descMetadata, rightsMetadata, and techMetadata datastreams are all
  # valid.
  def is_complete?
    false
  end

  def is_published?
    not self.avalon_publisher.blank?
  end

  def access
    logger.debug "<< ACCESS >>"
    logger.debug "<< #{self.read_groups} >>"
    
    if self.read_groups.empty?
      "private"
    elsif self.read_groups.include? "public"
      "public"
    elsif self.read_groups.include? "registered"
      "restricted" 
    end
  end

  def access= access_level
    if access_level == "public"
      groups = self.read_groups
      groups << 'public'
      groups << 'registered'
      self.read_groups = groups
    elsif access_level == "restricted"
      groups = self.read_groups
      groups.delete 'public'
      groups << 'registered'
      self.read_groups = groups
    else #private
      groups = self.read_groups
      groups.delete 'public'
      groups.delete 'registered'
      self.read_groups = groups
    end
  end
  
  def parts_with_order
    masterfiles = []
    descMetadata.relation_identifier.each do |pid|
      masterfiles << MasterFile.find(pid)
    end
    masterfiles
  end
  
  # Spatial and temporal are special cases that need to be handled a bit differently
  # than the rest. As a result we handle them first, take them out of the values
  # hash, and then pass the rest to be managed traditionally.
  #
  # This approach can also be used for other fields but be sure to keep good documentation
  # on the reasons why instead of just hacking something together in case it needs to be
  # referred to later.
  def update_datastream(datastream = :descMetadata, values = {})
    # Start with the coverage fields - since spatial and temporal both use
    # pbcoreCoverage we need to take care not to accidentally remove nodes which
    # were just inserted. One solution is create a new virtual attribute, coverage,
    # that includes the values to be updated. This can be synthesized before the
    # handoff to update_attribute
    #
    # WARNING - If there is already an entry in the hash for coverage it will be
    #           destroyed as a side effect. Note this when naming field variables or
    #           retool this code
    values[:pbcore_coverage] = []
    if values.has_key?(:spatial)
       logger.debug "<< Handling special case for attribute :spatial >>"
       values[:spatial].each do |spatial_value|
         next if spatial_value.blank?
         node = {value: spatial_value, attributes: 'Spatial'}
         values[:pbcore_coverage] << node
       end
       values.delete(:spatial)
    end
    
    if values.has_key?(:temporal)
       logger.debug "<< Handling special case for attribute :temporal >>"
       values[:temporal].each do |temporal_value|
         next if temporal_value.blank?
         node = {value: temporal_value, attributes: 'Temporal'}
         values[:pbcore_coverage] << node
       end
       values.delete(:temporal)
    end
    
    values.each do |k, v|
      # First remove all blank attributes in arrays
      v.keep_if { |item| not item.blank? } if v.instance_of?(Array)
      logger.debug "<< Updating #{k} >>"
      logger.debug "<< #{v} >>"

      # Peek at the first value in the array. If it is a Hash then unpack it into two
      # arrays before you pass everything off to the update_attributes method so that
      # the markup is composed properly
      #
      # This does not feel right but is just a first pass. Maybe the use of NOM rather
      # than OM will mitigate the need for such tricks
      if v.first.is_a?(Hash)
        vals = []
        attrs = []
        
        v.each do |entry|
          logger.debug "<< Entry : #{entry} >>"
          vals << entry[:value]
          attrs << entry[:attributes]
        end
        update_attribute(k, vals, attrs)
      else
        update_attribute(k, v)
      end
    end
  end
  
  def update_attribute(attribute, value = [], attributes = [])
    logger.debug "<< UPDATE ATTRIBUTE >>"
    logger.debug "<< Attribute : #{attribute} >>"
    logger.debug "<< Value : #{value} >>"
    logger.debug "<< Attributes : #{attributes} >>"
    
    # Add a special case for coverage. Eventually a more general approach should be
    # devised that can handle other elements with the same problem but this is just a
    # short term bandaid. If this is still here in December 2012 then the Agile process
    # is not working as it should
    if descMetadata.template_registry.has_node_type?(attribute.to_sym)
      active_nodes = descMetadata.find_by_terms(attribute.to_sym).length
      logger.debug "<< Need to remove #{active_nodes} old terms >>"
    
      active_nodes.times do |i|
        logger.debug "<< Deleting old node #{attribute}[#{i}] >>"
        descMetadata.remove_node(attribute.to_sym, 0)
      end

      value.length.times do |i|
        logger.debug "<< Adding node #{attribute}[#{i}] >>"
        descMetadata.add_child_node(descMetadata.ng_xml.root, attribute.to_sym, value[i], attributes[i])
      end
      #end
    else
      # Put in a placeholder so that the inserted nodes go into the right part of the
      # document. Afterwards take it out again - unless it does not have a template
      # in which case this is all that needs to be done
      if self.respond_to?("#{attribute}=", value)
        logger.debug "<< Calling delegated method #{attribute} >>"
        self.send("#{attribute}=", value)
      else
        logger.debug "<< Calling descMetadata method #{attribute} >>"
        descMetadata.send("#{attribute}=", value)
      end
    end
  end

  # Guarantees that the record is minimally complete - ie that within the descriptive
  # metadata the title, creator, date of creation, and identifier fields are not 
  # blank. Since identifier is set automatically we only need to worry about creator,
  # title, and date of creation.
  def minimally_complete_record
    logger.debug "<< MINIMALLY COMPLETE RECORD >>"
    
    [:creator, :title, :created_on].each do |element|
      logger.debug "<< Validating the #{element.to_sym} property >>"
      # Use send as a kludge for now. This does create some potential security issues
      # but these can be addressed since the loop's symbols are defined very locally
      # anyways
      if send(element).blank?
        errors.add element.to_sym, "The #{element.to_sym} field is required"
      end
    end
    logger.debug "<< #{errors.count} errors have been added to the session >>"
  end
  
  # Other validation to consider adding into future iterations is the ability to
  # validate against a known controlled vocabulary. This one will take some thought
  # and research as opposed to being able to just throw something together in an ad hoc
  # manner
  
  private
    def after_create
      self.DC.identifier = pid
      save
    end
end

