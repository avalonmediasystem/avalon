require 'role_controls'

class Unit < ActiveFedora::Base
  include ActiveFedora::Associations
  include Avalon::ManagerAssociation

  has_many :collections, property: :is_member_of
  has_metadata name: 'descMetadata', type: ModsDocument
  has_metadata name: 'objectMetadata', type: ActiveFedora::SimpleDatastream do |sds|
    sds.field :created_by_user_id, :string
    sds.field :collections_count, :integer
  end

  before_save :populate_dependent_attributes!

  delegate :name, to: :descMetadata, unique: true

  validates :name, :uniqueness => { :solr_name => 'name_t'}, presence: true

  def collections_count
    objectMetadata.collections_count.try :first || 0
  end
  
  #Move this into a decorator?
  def created_at
    if new?
      #Note that this time changes until it has been persisted in Fedora
      create_date.to_datetime
    else
      @created_at ||= DateTime.parse(create_date) 
    end
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
    super(solr_doc, opts)
    map = Solrizer::FieldMapper::Default.new
    solr_doc[ map.solr_name(:name, :string, :searchable).to_sym ] = self.name
    solr_doc[ map.solr_name(:collections_count, :integer, :sortable).to_sym ] = self.collections.count
    super(solr_doc)
  end
end

  private

    def populate_dependent_attributes!
      self.collections_count = self.collections.count
    end
end