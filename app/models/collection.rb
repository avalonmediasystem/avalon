class Collection < ActiveFedora::Base
  # include Hydra::ModelMethods
  include ActiveFedora::Associations
  include Hydra::ModelMixins::RightsMetadata

  belongs_to :unit, class_name: 'Unit', property: :is_part_of
  has_and_belongs_to_many :media_objects, property: :has_collection_member, class_name: 'MediaObject'
  has_metadata name: 'descMetadata', type: Hydra::ModsCollection
  has_metadata name: 'rightsMetadata', type: Hydra::Datastream::RightsMetadata 
  has_metadata name: 'objectMetadata', type: ActiveFedora::SimpleDatastream do |sds|
    sds.field :media_objects_count, :integer
  end

  before_save{|c| c.media_objects_count = self.media_objects.count }

  validates :name, presence: true
  
  delegate :name, to: :descMetadata, :unique => true
  delegate :media_objects_count, to: :objectMetadata

  attr_accessor :media_object_ids
  attr_reader :media_objects_count

  def media_objects_count
    objectMetadata.media_objects_count.try :first || 0
  end

  def created_at
    @created_at ||= DateTime.parse(create_date)
  end
  
  def to_solr(solr_doc = Hash.new, opts = {})
    map = Solrizer::FieldMapper::Default.new
    solr_doc[ map.solr_name(:media_object_count, :integer, :sortable).to_sym ] = self.media_objects_count
    super(solr_doc)
  end

end