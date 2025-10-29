# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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
  include Identifier
  include MigrationTarget
  include AdminCollectionBehavior

  belongs_to :unit, class_name: 'Admin::Unit', predicate: Avalon::RDFVocab::Bibframe.heldBy
  has_many :media_objects, class_name: 'MediaObject', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection

  validates :name, uniqueness: { solr_name: 'name_uniq_si' }, presence: true
  validates :unit, presence: true
  validates :managers, length: { minimum: 1, message: "list can't be empty." }
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :website_url, format: { with: URI.regexp }, allow_blank: true

  property :name, predicate: ::RDF::Vocab::DC.title, multiple: false do |index|
    index.as :stored_sortable
  end
  property :description, predicate: ::RDF::Vocab::DC.description, multiple: false do |index|
    index.as :stored_searchable
  end
  property :contact_email, predicate: ::RDF::Vocab::SCHEMA.email, multiple: false do |index|
    index.as :stored_sortable
  end
  property :website_label, predicate: Avalon::RDFVocab::Collection.website_label, multiple: false do |index|
    index.as :stored_sortable
  end
  property :website_url, predicate: ::RDF::Vocab::SCHEMA.url, multiple: false do |index|
    index.as :stored_sortable
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
  property :default_hidden, predicate: Avalon::RDFVocab::Collection.default_hidden, multiple: false do |index|
    index.as ActiveFedora::Indexing::Descriptor.new(:boolean, :stored, :indexed)
  end
  property :identifier, predicate: ::RDF::Vocab::Identifiers.local, multiple: true do |index|
    index.as :symbol
  end
  property :default_lending_period, predicate: ::RDF::Vocab::SCHEMA.eligibleDuration, multiple: false do |index|
    index.as :stored_sortable
  end
  property :cdl_enabled, predicate: Avalon::RDFVocab::Collection.cdl_enabled, multiple: false do |index|
    index.as ActiveFedora::Indexing::Descriptor.new(:boolean, :stored, :indexed)
  end
  property :collection_managers, predicate: Avalon::RDFVocab::Collection.collection_managers, multiple: true do |index|
    index.as :symbol
  end

  has_subresource 'poster', class_name: 'IndexedFile'

  around_save :reindex_members, if: Proc.new { |c| c.name_changed? }
  around_save :return_checkouts, if: Proc.new { |c| c.cdl_enabled_changed? && c.cdl_enabled == false }
  before_create :create_dropbox_directory!

  before_destroy :destroy_dropbox_directory!

  def created_at
    @created_at ||= create_date
  end

  def managers= users
    old_managers = managers
    users.each {|u| add_manager u}
    (old_managers - users).each {|u| remove_manager u}
  end

  def add_manager user
    raise ArgumentError, "User #{user} does not belong to the manager group." unless (Avalon::RoleControls.users("manager") + (Avalon::RoleControls.users("administrator") || []) ).include?(user)
    self.collection_managers += [user]
    self.edit_users += [user]
    self.inherited_edit_users += [user]
  end

  def remove_manager user
    return unless managers.include? user
    raise ArgumentError, "At least one manager is required." if self.managers.size == 1

    self.collection_managers = self.collection_managers.to_a - [user]
    self.edit_users -= [user]
    self.inherited_edit_users -= [user]
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
      raise ArgumentError, "User #{user} needs to be removed from manager or editor role before being added as a depositor."
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
    ReindexJob.perform_later(self.media_object_ids)
  end

  def return_checkouts
    yield
    BulkActionJobs::ReturnCheckouts.perform_later(self.id)
  end

  def to_solr
    super.tap do |solr_doc|
      solr_doc["unit_ssi"] = self.unit.name if self.unit.present?
      solr_doc["name_uniq_si"] = self.name.downcase.gsub(/\s+/,'') if self.name.present?
      solr_doc["has_poster_bsi"] = !(poster.content.nil? || poster.content == '')
    end
  end

  def as_json(options={})
    total_count = media_objects.count
    pub_count = published_count
    unpub_count = total_count - pub_count

    {
      id: id,
      name: name,
      unit: unit&.name,
      description: description,
      object_count: {
        total: total_count,
        published: pub_count,
        unpublished: unpub_count
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

  def dropbox_absolute_path( name = nil )
    File.join(Settings.dropbox.path, name || dropbox_directory_name)
  end

  def dropbox_object_count
    if Settings.dropbox.path =~ %r(^s3://)
      dropbox_path = Addressable::URI.parse(dropbox_absolute_path)
      response = Aws::S3::Client.new.list_objects(bucket: Settings.encoding.masterfile_bucket, max_keys: 10, prefix: "#{dropbox_path.path}/")
      response.contents.size
    else
      Dir["#{dropbox_absolute_path}/*"].count
    end
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
    self.default_read_groups.to_a - represented_default_visibility - default_local_read_groups - default_ip_read_groups
  end

  def default_visibility=(value)
    return if value.nil?
    # only set explicit permissions
    case value
    when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      public_default_visibility!
    when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      registered_default_visibility!
    when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      private_default_visibility!
    else
      raise ArgumentError, "Invalid default visibility: #{value.inspect}"
    end
  end

  def default_visibility
    if default_read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    elsif default_read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    else
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end
  end

  def default_visibility_changed?
    !!@default_visibility_will_change
  end

  alias_method :'_default_lending_period', :'default_lending_period'
  def default_lending_period
    self._default_lending_period || ActiveSupport::Duration.parse(Settings.controlled_digital_lending.default_lending_period).to_i
  end

  def cdl_enabled?
    if cdl_enabled.nil?
      Settings.controlled_digital_lending.collections_enabled
    elsif cdl_enabled != Settings.controlled_digital_lending.collections_enabled
      cdl_enabled
    else
      Settings.controlled_digital_lending.collections_enabled
    end
  end

  private

    def remove_edit_user(name)
      self.default_permissions = self.default_permissions.reject {|p| p.agent_name == name && p.type == 'person' && p.access == 'edit'}
    end

    def add_edit_user(name)
      self.default_permissions.build({name: name, type: 'person', access: 'edit'})
    end

    def create_dropbox_directory!
      if Settings.dropbox.path =~ %r(^s3://)
        create_s3_dropbox_directory!
      else
        create_fs_dropbox_directory!
      end
    end

    def destroy_dropbox_directory!
      DeleteDropboxJob.perform_later(dropbox_absolute_path)
    end

    def calculate_dropbox_directory_name
      name = self.dropbox_directory_name

      if name.blank?
        name = Avalon::Sanitizer.sanitize(self.name)
        iter = 2
        original_name = name.dup.freeze
        while yield(name)
          name = "#{original_name}_#{iter}"
          iter += 1
        end
      end
      name
    end

    def create_s3_dropbox_directory!
      base_uri = Addressable::URI.parse(Settings.dropbox.path)
      name = calculate_dropbox_directory_name do |n|
        obj = FileLocator::S3File.new(base_uri.join(n).to_s + '/').object
        obj.exists?
      end
      absolute_path = base_uri.join(name).to_s + '/.keep'
      obj = FileLocator::S3File.new(absolute_path).object
      Aws::S3::Client.new.put_object(bucket: obj.bucket_name, key: obj.key)
      self.dropbox_directory_name = name
    end

    def create_fs_dropbox_directory!
      name = calculate_dropbox_directory_name do |n|
        File.exist? dropbox_absolute_path(n)
      end

      absolute_path = dropbox_absolute_path(name)
      unless File.directory?(absolute_path)
        begin
          FileUtils.mkdir_p absolute_path
        rescue Exception => e
          Rails.logger.error "Could not create directory (#{absolute_path}): #{e.inspect}"
        end
      end
      self.dropbox_directory_name = name
    end

    # Override represented_visibility if you want to add another visibility that is
    # represented as a read group (e.g. on-campus)
    # @return [Array] a list of visibility types that are represented as read groups
    def represented_default_visibility
      [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED,
       Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
    end

    def default_visibility_will_change!
      @default_visibility_will_change = true
    end

    def public_default_visibility!
      default_visibility_will_change! unless default_visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      self.default_read_groups = self.default_read_groups.to_a - represented_visibility + [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
    end

    def registered_default_visibility!
      default_visibility_will_change! unless default_visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      self.default_read_groups = self.default_read_groups.to_a - represented_default_visibility + [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
    end

    def private_default_visibility!
      default_visibility_will_change! unless default_visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      self.default_read_groups = self.default_read_groups.to_a - represented_default_visibility
    end

    def published_count
      media_objects.where('avalon_publisher_ssi:["" TO *]').count
    end

    def unpublished_count
      media_objects.count - published_count
    end
end
