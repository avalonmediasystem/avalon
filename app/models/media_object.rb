class MediaObject < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods
  include ActiveFedora::Relationships
  include Hydra::ModelMixins::RightsMetadata

  has_relationship "parts", :has_part

  has_metadata name: "DC", type: DublinCoreDocument
  has_metadata name: "descMetadata", type: PbcoreDocument	

  after_create :after_create

  validates_each :creator, :created_on, :title do |record, attr, value|
    logger.debug "<< #{attr} => #{value} >>"
    record.errors.add(attr, "This field is required") if value.blank? or value.first == ""
  end
  
  delegate :uploader, to: :DC, at: [:creator]
  # Delegate variables to expose them for the forms
  delegate :title, to: :descMetadata, at: [:main_title]
  delegate :creator, to: :descMetadata, at: [:creator_name]
  delegate :created_on, to: :descMetadata, at: [:creation_date]
  delegate :abstract, to: :descMetadata, at: [:summary]
  delegate :format, to: :descMetadata, at: [:media_type], unique: true
  # Additional descriptive metadata
  delegate :contributor, to: :descMetadata, at: [:contributor_name]
  delegate :publisher, to: :descMetadata, at: [:publisher_name]
  delegate :genre, to: :descMetadata, at: [:genre], unique: true
  delegate :subject, to: :descMetadata, at: [:lc_subject]
  delegate :relatedItem, to: :descMetadata, at: [:relation]
  
  # Stub method to determine if the record is done or not. This should be based on
  # whether the descMetadata, rightsMetadata, and techMetadata datastreams are all
  # valid.
  def is_complete?
    false
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

  # Because of the complexity and time limitations spatial and temporal are going to
  # be dealt with by hand instead of relying on the delegate method. This means there
  # might still be some kinks to work out for the generic pbcoreCoverage but it gets
  # us moving forwards
  def spatial
      
  end
  
  def spatial=(values)
  end
  
  def temporal
  end
  
  def temporal=(values)
  end
  
  def update_datastream(datastream = :descMetadata, values = {})
    values.each do |k, v|
      update_attribute(k, v)
    end
  end
  
  def update_attribute(attribute, value = [])
    logger.debug "<< UPDATE ATTRIBUTE >>"
    active_nodes = descMetadata.find_by_terms(attribute)
    active_nodes.length.times do |i|
      logger.debug "<< Deleting old node #{attribute}[#{i}] >>"
      descMetadata.remove_node(attribute, i)
    end

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
    
    if descMetadata.template_registry.has_node_type?(attribute.to_sym)
      value.length.times do |i|
      logger.debug "<< Adding node #{attribute}[#{i}] >>"
        descMetadata.after_node(["#{attribute.to_sym}" => 0], attribute.to_sym, value[i], 'default')
      end
      logger.debug "<< Removing placeholder node >>"
      descMetadata.remove_node(attribute.to_sym, 0)
    else
    end
  end
  
  private
    def after_create
      self.DC.identifier = pid
      save
    end
end

