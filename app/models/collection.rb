require 'hydra/datastream/non_indexed_rights_metadata'

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
  has_metadata name: 'inheritedRights', type: Hydra::Datastream::InheritableRightsMetadata
  has_metadata name: 'defaultRights', type: Hydra::Datastream::NonIndexedRightsMetadata

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
    return unless RoleControls.users("manager").include?(user.username)
    self.edit_users += [user.username]
    self.inherited_edit_users += [user.username]
  end

  def remove_manager user
    return unless RoleControls.users("manager").include?(user.username)
    self.edit_users -= [user.username]
    self.inherited_edit_users -= [user.username]
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
    self.edit_users += [user.username]
    self.inherited_edit_users += [user.username]
    RoleControls.add_user_role(user.username, 'editor') unless RoleControls.users("editor").include?(user.username)
  end

  def remove_editor user
    return unless RoleControls.users("editor").include? user.username
    self.edit_users -= [user.username]
    self.inherited_edit_users -= [user.username]
    RoleControls.remove_user_role(user.username, 'editor') unless Collection.where("edit_access_person_t" => user.username).first
  end

  def depositors
    (inherited_edit_users & RoleControls.users("depositor")).map {|u| User.where(username: u).first}.compact
  end

  def depositors= users
    old_depositors = depositors
    users.each {|u| add_depositor u}
    (old_depositors - users).each {|u| remove_depositor u}
  end

  def add_depositor user
    self.inherited_edit_users += [user.username]
    RoleControls.add_user_role(user.username, 'depositor') unless RoleControls.users("depositor").include?(user.username)
  end

  def remove_depositor user
    return unless RoleControls.users("depositor").include? user.username
    self.inherited_edit_users -= [user.username]
    RoleControls.remove_user_role(user.username, 'depositor') unless Collection.where("inheritable_edit_access_person_t" => user.username).first
  end

  def inherited_edit_users
    inheritedRights.edit_access.machine.person
  end

  def inherited_edit_users= users
    p = {}
    (inherited_edit_users - users).each {|u| p[u] = 'none'}
    users.each {|u| p[u] = 'edit'}
    inheritedRights.update_permissions('person'=>p)
  end
end
