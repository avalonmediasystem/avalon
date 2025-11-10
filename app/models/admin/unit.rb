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

class Admin::Unit < ActiveFedora::Base
  include Hydra::AccessControls::Permissions
  include Hydra::AdminPolicyBehavior
  include ActiveFedora::Associations
  include Identifier
  include MigrationTarget
  include AdminUnitBehavior

  has_many :collections, class_name: 'Admin::Collection', predicate: Avalon::RDFVocab::Bibframe.heldBy

  validates :name, uniqueness: { solr_name: 'name_uniq_si' }, presence: true
  validates :unit_administrators, length: { minimum: 1, message: "list can't be empty." }
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
  property :website_label, predicate: Avalon::RDFVocab::Unit.website_label, multiple: false do |index|
    index.as :stored_sortable
  end
  property :website_url, predicate: ::RDF::Vocab::SCHEMA.url, multiple: false do |index|
    index.as :stored_sortable
  end
  property :default_read_users, predicate: Avalon::RDFVocab::Unit.default_read_users, multiple: true do |index|
    index.as :symbol
  end
  property :default_read_groups, predicate: Avalon::RDFVocab::Unit.default_read_groups, multiple: true do |index|
    index.as :symbol
  end
  property :default_hidden, predicate: Avalon::RDFVocab::Unit.default_hidden, multiple: false do |index|
    index.as ActiveFedora::Indexing::Descriptor.new(:boolean, :stored, :indexed)
  end
  property :identifier, predicate: ::RDF::Vocab::Identifiers.local, multiple: true do |index|
    index.as :symbol
  end
  property :collection_managers, predicate: Avalon::RDFVocab::Unit.collection_managers, multiple: true do |index|
    index.as :symbol
  end
  property :unit_administrators, predicate: Avalon::RDFVocab::Unit.unit_administrators, multiple: true do |index|
    index.as :symbol
  end

  has_subresource 'poster', class_name: 'IndexedFile'

  around_save :reindex_members, if: proc { |u| u.name_changed? }

  def created_at
    @created_at ||= create_date
  end

  def unit_admins=(users)
    old_admins = unit_admins
    users.each { |u| add_unit_admin u }
    (old_admins - users).each { |u| remove_unit_admin u }
  end

  def add_unit_admin(user)
    raise ArgumentError, "User #{user} does not belong to the unit administrator group." unless (Avalon::RoleControls.users("unit_administrator") + (Avalon::RoleControls.users("administrator") || [])).include?(user)
    self.unit_administrators += [user]
    self.edit_users += [user]
    self.inherited_edit_users += [user]
  end

  def remove_unit_admin(user)
    return unless unit_admins.include? user
    raise ArgumentError, "At least one unit administrator is required." if self.unit_administrators.size == 1

    self.unit_administrators = self.unit_administrators.to_a - [user]
    self.edit_users -= [user]
    self.inherited_edit_users -= [user]
  end

  def managers= users
    old_managers = managers
    users.each { |u| add_manager u }
    (old_managers - users).each { |u| remove_manager u }
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
    default_permissions.select { |p| p.access == 'edit' && p.type == 'person' }.collect(&:agent_name)
  end

  def inherited_edit_users=(users)
    (inherited_edit_users - users).each { |u| remove_edit_user(u) }
    (users - inherited_edit_users).each { |u| add_edit_user(u) }
  end

  def collections_to_json
    collections.collect { |c| [c.id, c.to_json] }.to_h
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

  def reindex_members
    yield
    ReindexJob.perform_later(self.collection_ids)
    # TODO Also need to reindex all media objects in the collections of this unit
  end

  def to_solr
    super.tap do |solr_doc|
      solr_doc["name_uniq_si"] = self.name.downcase.gsub(/\s+/, '') if self.name.present?
      solr_doc["has_poster_bsi"] = !(poster.content.nil? || poster.content == '')
    end
  end

  def as_json(_options = {})
    {
      id: id,
      name: name,
      description: description,
      object_count: {
        total: collections.count
      },
      roles: {
        unit_admins: unit_admins,
        managers: managers,
        editors: editors,
        depositors: depositors
      }
    }
  end

  def self.autocomplete(query, _id = nil)
    # Search name_uniq_si for case insensitivity since that field is downcased
    # name_uniq_si has no whitespace, so remove whitespace from the query
    solr_query = "name_uniq_si: (#{query.downcase.gsub(/\s+/, '')}*)"
    # To take advantage of solr automagically escaping characters the query has to be in single quotes.
    # This runs counter to ruby's string interpolation which requires the string to be in double quotes.
    # We can get around this by using format.
    filter = format('has_model_ssim: "%s"', "Admin::Unit")

    search_array = ActiveFedora::SolrService.query(solr_query, rows: 1000, fq: filter)

    search_array.map { |value| { id: value[:id], display: value[:name_ssi] } }
  end

  private

  def remove_edit_user(name)
    self.default_permissions = self.default_permissions.reject { |p| p.agent_name == name && p.type == 'person' && p.access == 'edit' }
  end

  def add_edit_user(name)
    self.default_permissions.build({ name: name, type: 'person', access: 'edit' })
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
end
