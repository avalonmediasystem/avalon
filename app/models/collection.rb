class Collection < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include ActiveFedora::Associations
  include Hydra::ModelMixins::RightsMetadata

  has_and_belongs_to_many :media_objects, property: :has_collection_member, class_name: 'MediaObject' 
  has_metadata name: 'descMetadata', type: ActiveFedora::SimpleDatastream do |sds|
    sds.field :name, :string
    sds.field :unit, :string
    sds.field :description, :string
  end
  has_metadata name: 'defaultRights', type: Hydra::Datastream::InheritableRightsMetadata

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
    (edit_users & RoleControls.users("manager")).map {|u| User.where(username: u).first}.compact
  end

  def managers= users
    old_managers = managers
    users.each {|u| add_manager u}
    (old_managers - users).each {|u| remove_manager u}
  end

  def add_manager user
    rightsMetadata.update_permissions({"person" => {user.username => "edit"}}) if RoleControls.user_roles(user.username).include?("manager")
  end

  def remove_manager user
    rightsMetadata.update_permissions({"person" => {user.username => "none"}}) if RoleControls.user_roles(user.username).include?("manager")
  end

  def editors
    (edit_users & RoleControls.users("editor")).map {|u| User.where(username: u).first}.compact
  end

  def editors= users
    old_editors = editors
    users.each {|u| add_editor u}
    (old_editors - users).each {|u| remove_editor u}
  end

  def add_editor user
    rightsMetadata.update_permissions({"person" => {user.username => "edit"}})
    RoleControls.add_user_role(user.username, 'editor') unless RoleControls.user_roles(user.username).include?("editor")
  end

  def remove_editor user
    rightsMetadata.update_permissions({"person" => {user.username => "none"}})
    RoleControls.remove_user_role(user.username, 'editor') unless Collection.where("edit_access_person_t" => user.username).first
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

