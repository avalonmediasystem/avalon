class Video < ActiveFedora::Base
  include Hydra::ModelMethods
  # This is the new and apparently preferred way of handling mixins
  include Hydra::ModelMixins::RightsMetadata
    
  has_metadata name: "DC", type: DublinCoreDocument
  has_metadata name: "descMetadata", type: PbcoreDocument
  has_metadata name: "rightsMetadata", type: Hydra::Datastream::RightsMetadata

  after_create :after_create
#  validates :creator, :has_valid_metadata_value
#  validates :created_on, :has_valid_metadata_value
#  validates :title, :has_valid_metadata_value

  private
  def validate
    puts "<< Validating required metadata fields >>"
    unless is_valid_metadata_field?(creator, true)
      errors.add(:creator, "This field is required")
    end
    
    unless is_valid_metadata_field(created_on, true)
      errors.add(:created_on, "This field is required")
    end
    
    unless is_valid_metadata_field(title, true)
      errors.add(:title, "This field is required")
    end
  end
  
    def after_create
      self.DC.identifier = pid
      save
    end
    
    # This really should live in a Validation helper, the OM model, or somewhere
    # else that is not a quick and dirty hack
    def has_valid_metadata_value(field, required=false)
      puts "<< Validating #{field} >>"
      
      # True cases to fail validation should live here
      unless descMetadata[field].nil?
        if required 
          return ((not descMetadata[field].empty?) and 
            (not "" == descMetadata[field].first))
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
