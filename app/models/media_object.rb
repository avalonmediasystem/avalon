class MediaObject < ActiveFedora::Base

  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods
  include ActiveFedora::FileManagement
  include Hydra::ModelMixins::RightsMetadata

  has_metadata name: "descMetadata", type: PbcoreDocument	

  validate :presence_of_required_metadata

  # Delegate variables to expose them for the forms
  delegate :title, to: :descMetadata, at: [:main_title]
  delegate :creator, to: :descMetadata, at: [:creator_name]
  delegate :created_on, to: :descMetadata, at: [:creation_date]
  delegate :abstract, to: :descMetadata, at: [:summary]
  delegate :uploader, to: :descMetadata, at: [:publisher_name]
  delegate :format, to: :descMetadata, at: [:media_type]
    
  def presence_of_required_metadata
    logger.debug "<< Validating required metadata fields >>"
    unless has_valid_metadata_value(:creator, true)
      errors.add(:creator, "This field is required")
    end
    
    unless has_valid_metadata_value(:created_on, true)
      errors.add(:created_on, "This field is required")
    end
    
    unless has_valid_metadata_value(:title, true)
      errors.add(:title, "This field is required")
    end
  end


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

  def parts_append obj
      #Copied from ActiveFedora::FileManagement
      unless obj.kind_of? ActiveFedora::Base
        begin
          obj = ActiveFedora::Base.find(obj)
        rescue ActiveFedora::ObjectNotFoundError
          "You must provide either an ActiveFedora object or a valid pid to add it as a file object. You submitted #{obj.inspect}"
        end
      end
      obj.add_relationship(:is_part_of, self)
      obj.save
  end

  private


    # This really should live in a Validation helper, the OM model, or somewhere
    # else that is not a quick and dirty hack
    def has_valid_metadata_value(field, required=false)
      logger.debug "<< Validating #{field} >>"
      
      # True cases to fail validation should live here
      unless self.send(field).nil?
        if required 
          return ((not self.send(field).empty?) and 
            (not "" == self.send(field).first))
        else 
          # If it isn't required then return true even if it is empty
          return true
        end
      else
        # Always return false when nil
        return false
      end     
    end

end

