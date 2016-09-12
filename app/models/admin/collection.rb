# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

require 'avalon/role_controls'
require 'avalon/controlled_vocabulary'
require 'avalon/sanitizer'

class Admin::Collection < ActiveFedora::Base
  include Hydra::AccessControls::Permissions
  include Hydra::AdminPolicyBehavior
  include ActiveFedora::Associations

  has_many :media_objects, class_name: 'MediaObject', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection

  validates :name, :uniqueness => { :solr_name => 'name_uniq_si'}, presence: true
  validates :unit, presence: true, inclusion: { in: Proc.new{ Admin::Collection.units } }
  validates :managers, length: {minimum: 1, message: "list can't be empty."}

  property :name, predicate: ::RDF::Vocab::DC.title, multiple: false do |index|
    index.as :stored_sortable
  end
  property :unit, predicate: ::RDF::Vocab::Bibframe.heldBy, multiple: false do |index|
    index.as :stored_sortable
  end
  property :description, predicate: ::RDF::Vocab::DC.description, multiple: false do |index|
    index.as :stored_searchable
  end
  property :dropbox_directory_name, predicate: Avalon::RDFVocab::Collection.dropbox_directory_name, multiple: false do |index|
    index.as :stored_sortable
  end
  property :default_read_users, predicate: Avalon::RDFVocab::Collection.default_read_users, multiple: true do |index|
    index.as :symbol
  end
  property :default_read_groups, predicate: Avalon::RDFVocab::Collection.default_read_groups, multiple: true do |index|
    index.as :symbol
  end
  property :default_visibility, predicate: Avalon::RDFVocab::Collection.default_visibility, multiple: false do |index|
    index.as :stored_sortable
  end
  property :default_hidden, predicate: Avalon::RDFVocab::Collection.default_hidden, multiple: false do |index|
    index.as Solrizer::Descriptor.new(:boolean, :stored, :indexed)
  end
  property :identifier, predicate: ::RDF::Vocab::Identifiers.local, multiple: true do |index|
    index.as :facetable
  end

  around_save :reindex_members, if: Proc.new{ |c| c.name_changed? or c.unit_changed? }
  after_validation :create_dropbox_directory!, :on => :create

  def self.units
    Avalon::ControlledVocabulary.find_by_name(:units) || []
  end

  def created_at
    @created_at ||= create_date
  end

  def managers
    edit_users & ( Avalon::RoleControls.users("manager") | (Avalon::RoleControls.users("administrator") || []) )
  end

  def managers= users
    old_managers = managers
    users.each {|u| add_manager u}
    (old_managers - users).each {|u| remove_manager u}
  end

  def add_manager user
    raise ArgumentError, "User #{user} does not belong to the manager group." unless (Avalon::RoleControls.users("manager") + (Avalon::RoleControls.users("administrator") || []) ).include?(user)
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
    edit_users - managers
  end

  def editors= users
    old_editors = editors
    users.each {|u| add_editor u}
    (old_editors - users).each {|u| remove_editor u}
  end

  def add_editor user
    self.edit_users += [user]
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
    # Do not add an edit_user to read_users or they will be removed from edit_users
    unless self.edit_users.include? user
      self.read_users += [user]
      self.inherited_edit_users += [user]
    else
      raise ArgumentError.new("UserIsEditor")
    end
  end

  def remove_depositor user
    return unless depositors.include? user
    self.read_users -= [user]
    self.inherited_edit_users -= [user]
  end

  def inherited_edit_users
    default_permissions.select {|p| p.access == 'edit' && p.type == 'person'}.collect(&:agent_name)
  end

  def inherited_edit_users= users
    (inherited_edit_users - users).each { |u| remove_edit_user(u) }
    (users - inherited_edit_users).each { |u| add_edit_user(u) }
  end

  def self.reassign_media_objects( media_objects, source_collection, target_collection)
    media_objects.each do |media_object|
      media_object.collection = target_collection
      media_object.save
    end
  end

  def reindex_members
    yield
    self.class.reindex_media_objects id
  end

  class << self
    def reindex_media_objects id
      collection = self.find id
      collection.media_objects.each{|mo| mo.update_index}
    end
    handle_asynchronously :reindex_media_objects
  end

  def to_solr
    super.tap do |solr_doc|
      solr_doc["name_uniq_si"] = self.name.downcase.gsub(/\s+/,'') if self.name.present?
    end
  end

  def as_json(options={})
    {
      id: id,
      name: name,
      unit: unit,
      description: description,
      object_count: {
        total: media_objects.count,
        published: media_objects.reject{|mo| !mo.published?}.count,
        unpublished: media_objects.reject{|mo| mo.published?}.count
      },
      roles: {
        managers: managers,
        editors: editors,
        depositors: depositors
      }
    }
  end

  def dropbox
    Avalon::Dropbox.new( dropbox_absolute_path, self )
  end

  def dropbox_absolute_path( name = '' )
    File.join(Avalon::Configuration.lookup('dropbox.path'), name || dropbox_directory_name)
  end

  def media_objects_to_json
    media_objects.collect{|mo| [mo.id, mo.to_json] }.to_h
  end

  def default_local_read_groups
    self.default_read_groups.select {|g| Admin::Group.exists? g}
  end

  def default_ip_read_groups
    self.default_read_groups.select {|g| IPAddr.new(g) rescue false }
  end

  def default_virtual_read_groups
    self.default_read_groups - ["public", "registered"] - default_local_read_groups - default_ip_read_groups
  end

  private

    def remove_edit_user(name)
      self.default_permissions = self.default_permissions.reject {|p| p.agent_name == name && p.type == 'person' && p.access == 'edit'}
    end

    def add_edit_user(name)
      self.default_permissions.build({name: name, type: 'person', access: 'edit'})
    end

    def create_dropbox_directory!
      name = self.dropbox_directory_name

      if name.blank?
        name = Avalon::Sanitizer.sanitize(self.name)
        iter = 2
        original_name = name.dup.freeze

        while File.exist? dropbox_absolute_path(name)
          name = "#{original_name}_#{iter}"
          iter += 1
        end
      end

      absolute_path = dropbox_absolute_path(name)

      unless File.directory?(absolute_path)
        begin
          Dir.mkdir(absolute_path)
        rescue Exception => e
          Rails.logger.error "Could not create directory (#{absolute_path}): #{e.inspect}"
        end
      end
      self.dropbox_directory_name = name
    end

end
