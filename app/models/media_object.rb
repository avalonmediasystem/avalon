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
  delegate :format, to: :descMetadata, at: [:media_type]
  # Additional descriptive metadata
  delegate :contributor, to: :descMetadata, at: [:contributor_name]
  delegate :publisher, to: :descMetadata, at: [:publisher_name]
  delegate :genre, to: :descMetadata, at: [:genre]
  delegate :spatial, to: :descMetadata, at: [:spatial]
  delegate :temporal, to: :descMetadata, at: [:temporal]
  delegate :subject, to: :descMetadata, at: [:lc_subject]
  delegate :relatedItem, to: :descMetadata, at: [:relation]
  
  # Stub method to determine if the record is done or not. This should be based on
  # whether the descMetadata, rightsMetadata, and techMetadata datastreams are all
  # valid.
  def is_complete?
    false
  end

  def access
    logger.debug "<< Access level >>"
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
      update_attribute(k, v)
    end
  end
  
  def update_attribute(attribute, value = [])
    active_nodes = descMetadata.find_by_terms(attribute)
    active_nodes.length.times do |i|
      descMetadata.remove_node(attribute, i)
    end
    
    if descMetadata.respond_to?("#{attribute}_template".to_sym)
      value.length.times do |i|
        descMetadata.insert_node(attribute, value[i])
      end
    else
      if self.respond_to?("#{attribute}=", value)
        self.send("#{attribute}=", value)
      else
        descMetadata.send("#{attribute}=", value)
      end
    end
  end
  
  private
    def after_create
      self.DC.identifier = pid
      save
    end
end

