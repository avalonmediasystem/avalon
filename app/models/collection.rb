class Collection < ActiveFedora::Base
  include Hydra::ModelMethods
  include Hydra::ModelMixins::RightsMetadata

  belongs_to :unit, class_name: 'Unit', property: :is_part_of
  has_and_belongs_to_many :media_objects, property: :has_collection_member, class_name: 'MediaObject'
  has_metadata name: 'descMetadata', type: Hydra::ModsCollection
  has_metadata :name => 'rightsMetadata', type: Hydra::Datastream::RightsMetadata 
  
  attr_accessor :media_object_ids
  delegate :name, to: :descMetadata, unique: true

  validates :name, presence: true

  def created_at
    @created_at ||= DateTime.parse(create_date)
  end

end