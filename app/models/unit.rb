require 'role_controls'

class Unit < ActiveFedora::Base
  include ActiveFedora::Associations  
  has_metadata name: "descMetadata", type: ModsDocument

  has_and_belongs_to_many :managers, property: :has_managers, property: 'User'
  has_and_belongs_to_many :collections, property: :has_collections, class_name: 'Collection'

  has_metadata name: 'objectMetadata', type: ActiveFedora::SimpleDatastream do |sds|
    sds.field :created_by_user_id, :string
  end

  delegate :name, to: :descMetadata, unique: true
  delegate :created_by_user_id, to: :objectMetadata

  validates :name, presence: true

  def created_at
    @created_at ||= DateTime.parse(create_date)
  end
end
