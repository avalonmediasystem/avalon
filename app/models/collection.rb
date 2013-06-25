class Collection < ActiveFedora::Base
  include ActiveFedora::Associations
  include Hydra::ModelMixins::RightsMetadata

  has_and_belongs_to_many :media_objects, property: :has_collection_member, class_name: 'MediaObject' 
  has_metadata name: 'descMetadata', type: ActiveFedora::SimpleDatastream do |sds|
    sds.field :name, :string
    sds.field :unit, :string
    sds.field :description, :string
  end
  has_metadata name: 'rightsMetadata', type: Hydra::Datastream::RightsMetadata, autocreate: true 
  has_metadata name: 'defaultRights', type: Hydra::Datastream::InheritableRightsMetadata, autocreate: true

  validates :name, :uniqueness => { :solr_name => 'name_t'}, presence: true
  validates :unit, presence: true, inclusion: ["University Archives", "Black Film Center/Archive"] 

  delegate :name, to: :descMetadata, unique: true
  delegate :unit, to: :descMetadata, unique: true
  delegate :description, to: :descMetadata, unique: true

  def created_at
    @created_at ||= DateTime.parse(create_date)
  end

  def to_solr(solr_doc = Hash.new, opts = {})
    map = Solrizer::FieldMapper::Default.new
    solr_doc[ map.solr_name(:name, :string, :searchable).to_sym ] = self.name
    super(solr_doc)
  end

  def managers
    edit_users & RoleControls.users("manager") 
  end

  def managers= users
    users.each do |u|
      rightsMetadata.permissions({user: u.username}, "edit")
      RoleControls.add_user_role(u.username, 'manager') unless RoleControls.user_roles(u.username).include? "manager"
    end
  end

  def editors
    edit_users & RoleControls.users("editor") 
  end

  def editors= users
    users.each do |u|
      rightsMetadata.permissions({user: u.username}, "edit")
      RoleControls.add_user_role(u.username, 'editor') unless RoleControls.user_roles(u.username).include? "editor"
    end
  end

  def depositors
    defaultRights.edit_access.machine.person & RoleControls.users("depositor") 
  end

  def depositors= users
    users.each do |u|
      defaultRights.permissions({user: u.username}, "edit")
      RoleControls.add_user_role(u.username, 'depositor') unless RoleControls.user_roles(u.username).include? "depositor"
    end
  end
end

