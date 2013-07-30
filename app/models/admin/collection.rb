require 'hydra/datastream/non_indexed_rights_metadata'
require 'hydra/model_mixins/hybrid_delegator'
require 'role_controls'
require 'avalon/controlled_vocabulary'

class Admin::Collection < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include ActiveFedora::Associations
  include Hydra::ModelMixins::RightsMetadata
  include Hydra::ModelMixins::HybridDelegator

  has_many :media_objects, property: :is_member_of_collection 
  has_metadata name: 'descMetadata', type: ActiveFedora::SimpleDatastream do |sds|
    sds.field :name, :string
    sds.field :unit, :string
    sds.field :description, :string
  end
  has_metadata name: 'inheritedRights', type: Hydra::Datastream::InheritableRightsMetadata
  has_metadata name: 'defaultRights', type: Hydra::Datastream::NonIndexedRightsMetadata, autocreate: true

  validates :name, :uniqueness => { :solr_name => 'name_tesim'}, presence: true
  validates :unit, presence: true, inclusion: { in: Proc.new{ Admin::Collection.units } }
  validates :managers, length: {minimum: 1, message: 'Collection requires at least 1 manager'} 

  delegate :name, to: :descMetadata, unique: true
  delegate :unit, to: :descMetadata, unique: true
  delegate :description, to: :descMetadata, unique: true
  delegate :read_groups, :read_users, :access, :access=, :hidden?, :hidden=, :group_exceptions,
           :group_exceptions=, :user_exceptions, :user_exceptions=, to: :defaultRights, prefix: :default

  def self.units
    Avalon::ControlledVocabulary.find_by_name(:units)
  end

  def created_at
    @created_at ||= DateTime.parse(create_date)
  end

  def to_solr(solr_doc = Hash.new, opts = {})
    map = Solrizer::default_field_mapper
    solr_doc[ map.solr_name(:name, :stored_searchable, type: :string).to_sym ] = self.name
    super(solr_doc)
  end

  def managers
    edit_users & (RoleControls.users("manager") || [])
  end

  def managers= users
    old_managers = managers
    users.each {|u| add_manager u}
    (old_managers - users).each {|u| remove_manager u}
  end

  def add_manager user
    return unless RoleControls.users("manager").include?(user)
    self.edit_users += [user]
    self.inherited_edit_users += [user]
  end

  def remove_manager user
    return unless managers.include? user
    #raise "OneManagerLeft" if self.managers.size == 1 # Requires at least 1 manager

    self.edit_users -= [user]
    self.inherited_edit_users -= [user]
  end

  def editors
    edit_users - RoleControls.users("manager")
  end

  def editors= users
    old_editors = editors
    users.each {|u| add_editor u}
    (old_editors - users).each {|u| remove_editor u}
  end

  def add_editor user
    self.edit_users += [user]
    logger.debug "EDIT USERS #{self.edit_users}"
    self.inherited_edit_users += [user]
  end

  def remove_editor user
    return unless editors.include? user
    self.edit_users -= [user]
    self.inherited_edit_users -= [user]
  end

  def depositors
    read_users
  end

  def depositors= users
    old_depositors = depositors
    users.each {|u| add_depositor u}
    (old_depositors - users).each {|u| remove_depositor u}
  end

  def add_depositor user
    # Do not add an edit_user to read_users or he will be removed from edit_users
    unless self.edit_users.include? user
      self.read_users += [user]
      self.inherited_edit_users += [user]
    else
      raise "UserIsEditor"
    end
  end

  def remove_depositor user
    return unless depositors.include? user
    self.read_users -= [user]
    self.inherited_edit_users -= [user]
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

  def self.reassign_media_objects( media_objects, source_collection, target_collection)
    media_objects.dup.each do |media_object|
      
      source_collection.remove_relationship(:is_member_of_collection, "info:fedora/#{media_object.pid}")
      source_collection.media_objects.delete media_object

      target_collection.add_relationship(:is_member_of_collection, "info:fedora/#{media_object.pid}")
      target_collection.media_objects << media_object

      media_object.collection = target_collection
      media_object.save!
    end
    source_collection.save!
    target_collection.save!
  end

end
