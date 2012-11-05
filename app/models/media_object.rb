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
  before_save 'descMetadata.ensure_identifier_exists!', prepend: true
  before_save 'descMetadata.update_change_date!', prepend: true
  before_save 'descMetadata.reorder_elements!', prepend: true
  
  # Call custom validation methods to ensure that required fields are present and
  # that preferred controlled vocabulary standards are used
  validate :minimally_complete_record
  
  delegate :avalon_uploader, to: :DC, at: [:creator], unique: true
  delegate :avalon_publisher, to: :DC, at: [:publisher], unique: true
  # Delegate variables to expose them for the forms
  delegate :title, to: :descMetadata, at: [:main_title], unique: true
  delegate :alternative_title, to: :descMetadata, at: [:alternative_title]
  delegate :translated_title, to: :descMetadata, at: [:translated_title]
  delegate :uniform_title, to: :descMetadata, at: [:uniform_title]
  delegate :statement_of_responsibility, to: :descMetadata, at: [:statement_of_responsibility], unique: true
  delegate :creator, to: :descMetadata, at: [:creator], unique: true
  delegate :date_created, to: :descMetadata, at: [:date_created], unique: true
  delegate :date_issued, to: :descMetadata, at: [:date_issued], unique: true
  delegate :copyright_date, to: :descMetadata, at: [:copyright_date], unique: true
  delegate :abstract, to: :descMetadata, at: [:abstract], unique: true
  delegate :note, to: :descMetadata, at: [:note]
  delegate :format, to: :descMetadata, at: [:media_type], unique: true
  # Additional descriptive metadata
  delegate :contributor, to: :descMetadata, at: [:contributor]
  delegate :publisher, to: :descMetadata, at: [:publisher]
  delegate :genre, to: :descMetadata, at: [:genre], unique: true
  delegate :subject, to: :descMetadata, at: [:topical_subject]
  delegate :relatedItem, to: :descMetadata, at: [:related_item_id]

  delegate :geographic_subject, to: :descMetadata, at: [:geographic_subject]
  delegate :temporal_subject, to: :descMetadata, at: [:temporal_subject]
  
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
  
  def update_datastream(datastream = :descMetadata, values = {})
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
        update_attribute(k, Array(v))
      end
    end
    logger.debug(datastreams[datastream.to_s].to_xml)
  end
  
  def update_attribute(attribute, value = [], attributes = [])
    logger.debug "<< UPDATE ATTRIBUTE >>"
    logger.debug "<< Attribute : #{attribute.inspect} >>"
    logger.debug "<< Value : #{value.inspect} >>"
    logger.debug "<< Attributes : #{attributes.inspect} >>"

    descMetadata.find_by_terms(attribute.to_sym).each &:remove
    if descMetadata.template_registry.has_node_type?(attribute.to_sym)
      Array(value).each_with_index do |val, i|
        logger.debug "<< Adding node #{attribute}[#{i}] >>"
        logger.debug("descMetadata.add_child_node(descMetadata.ng_xml.root, #{attribute.to_sym.inspect}, #{val.inspect}, #{(attributes[i]||{}).inspect})")
        descMetadata.add_child_node(descMetadata.ng_xml.root, attribute.to_sym, val, (attributes[i]||{}))
      end
      #end
    elsif descMetadata.respond_to?("add_#{attribute}")
      Array(value).each_with_index do |val, i|
        logger.debug("descMetadata.add_#{attribute}(#{val.inspect}, #{attributes[i].inspect})")
        descMetadata.send("add_#{attribute}", val, (attributes[i] || {}))
      end;
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
    
    [:creator, :title, :date_created].each do |element|
      logger.debug "<< Validating the #{element.to_sym} property >>"
      # Use send as a kludge for now. This does create some potential security issues
      # but these can be addressed since the loop's symbols are defined very locally
      # anyways
      if send(element).blank?
        errors.add element.to_sym, "The #{element.to_sym} field is required"
        logger.info "<< ERROR: #{element} is required"
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

