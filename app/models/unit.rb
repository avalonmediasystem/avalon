require 'role_controls'

class Unit < ActiveFedora::Base
  include ActiveFedora::Associations

  has_metadata name: 'descMetadata', type: ModsDocument
  belongs_to :collection, property: :is_member_of, class_name: 'Collection'
  has_metadata name: 'objectMetadata', type: ActiveFedora::SimpleDatastream do |sds|
    sds.field :created_by_user_id, :string
    sds.field :collections_count, :integer
  end

  delegate :name, to: :descMetadata, unique: true
  delegate :created_by_user_id, to: :objectMetadata
  delegate :collections_count, to: :objectMetadata

  validates :name, :uniqueness => { :solr_name => 'name_t'}, presence: true


  def created_at
    @created_at ||= DateTime.parse(create_date)
  end

  def managers
    return [] unless relationships(:has_member).present?
    User.find(relationships(:has_member).map{|m| m.to_s.delete('info:fedora/').to_i })
  end

  def managers=( users )
    clear_relationship :has_member
    users.each do |user|
      self.add_relationship(:has_member,  RDF::Literal.new("info:fedora/#{user.id}"))
    end
  end


  def to_solr(solr_doc = Hash.new, opts = {})
    map = Solrizer::FieldMapper::Default.new
    solr_doc[ map.solr_name(:name, :string, :searchable).to_sym ] = self.name
    solr_doc[ map.solr_name(:collectios_count, :integer, :sortable).to_sym ] = self.collections_count
    super(solr_doc)
  end
end