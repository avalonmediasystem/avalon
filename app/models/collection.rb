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

  before_save :populate_dependent_attributes!

  validates :name, :uniqueness => { :solr_name => 'name_t'}, presence: true
  validates :unit, inclusion: { in: Proc.new{ Unit.all } }, allow_nil: true
  
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

  def thumbnail_urls( number = 1 )
    media_objects.map.take(number) do |media_object|
      iter += 1
      if iter < number
        media_object.thumbnail_url
      end
    end.compact
  end

  def to_solr(solr_doc = Hash.new, opts = {})
    map = Solrizer::FieldMapper::Default.new
    solr_doc[ map.solr_name(:name, :string, :searchable).to_sym ] = self.name
    solr_doc[ map.solr_name(:media_object_count, :integer, :sortable).to_sym ] = self.media_objects_count
    super(solr_doc)
  end

  private

    def populate_dependent_attributes!
      self.media_objects_count = self.media_objects.count
    end
end