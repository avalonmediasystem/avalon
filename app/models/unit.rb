require 'role_controls'

class Unit < ActiveFedora::Base
  has_metadata name: "descMetadata", type: ModsDocument

  has_and_belongs_to_many :managers, property: :has_managers, property: 'User'
  has_and_belongs_to_many :collections, property: :has_collections, class_name: 'Collection'

  delegate :name, to: :descMetadata, unique: true

  def created_at
    @created_at ||= DateTime.parse(create_date)
  end
end