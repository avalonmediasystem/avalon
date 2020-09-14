# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

class MediaObject < ActiveFedora::Base
  include Hydra::AccessControls::Permissions
  include Hidden
  include VirtualGroups
  include ActiveFedora::Associations
  include MediaObjectMods
  include Avalon::Workflow::WorkflowModelMixin
  include Permalink
  include Identifier
  include MigrationTarget
  include SpeedyAF::OrderedAggregationIndex
  include MediaObjectIntercom
  include SupplementalFileBehavior
  require 'avalon/controlled_vocabulary'

  include Kaminari::ActiveFedoraModelExtension

  has_and_belongs_to_many :governing_policies, class_name: 'ActiveFedora::Base', predicate: ActiveFedora::RDF::ProjectHydra.isGovernedBy
  belongs_to :collection, class_name: 'Admin::Collection', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection

  before_save :update_dependent_properties!, prepend: true
  before_save :update_permalink, if: Proc.new { |mo| mo.persisted? && mo.published? }, prepend: true
  before_save :assign_id!, prepend: true
  after_save :update_dependent_permalinks_job, if: Proc.new { |mo| mo.persisted? && mo.published? }
  after_save :remove_bookmarks

  # Call custom validation methods to ensure that required fields are present and
  # that preferred controlled vocabulary standards are used

  # Guarantees that the record is minimally complete - ie that within the descriptive
  # metadata the title, creator, date of creation, and identifier fields are not
  # blank. Since identifier is set automatically we only need to worry about creator,
  # title, and date of creation.

  validates :collection, presence: true
  # validates :governing_policies, presence: true if Proc.new { |mo| mo.changes["governing_policy_ids"].empty? }

  validates :title, presence: true, if: :resource_description_active?
  validates :date_issued, presence: true, if: :resource_description_active?
  validate  :validate_language, if: :resource_description_active?
  validate  :validate_related_items, if: :resource_description_active?
  validate  :validate_dates, if: :resource_description_active?
  validate  :validate_note_type, if: :resource_description_active?
  validate  :report_missing_attributes, if: :resource_description_active?
  validate  :validate_rights_statement, if: :resource_description_active?

  def resource_description_active?
    workflow.completed?("file-upload")
  end

  def validate_rights_statement
    errors.add(:rights_statement, "Rights statement (#{rights_statement}) not in controlled vocabulary") unless rights_statement.nil? || ModsDocument::RIGHTS_STATEMENTS.keys.include?(rights_statement)
  end

  def validate_note_type
    Array(note).each{|i|errors.add(:note, "Note type (#{i[:type]}) not in controlled vocabulary") unless ModsDocument::NOTE_TYPES.keys.include? i[:type] }
  end

  def validate_language
    Array(language).each{|i|errors.add(:language, "Language not recognized (#{i[:code]})") unless LanguageTerm::map[i[:code]] }
  end

  def validate_related_items
    Array(related_item_url).each{|i|errors.add(:related_item_url, "Bad URL") unless i[:url] =~ URI::regexp(%w(http https))}
  end

  def validate_dates
    validate_date :date_created
    validate_date :date_issued
    validate_date :copyright_date
  end

  def validate_date(date_field)
    date = send(date_field)
    return if date.blank?
    edtf_date = Date.edtf(date)
    if edtf_date.nil? || edtf_date.class == EDTF::Unknown # remove second condition to allow 'uuuu'
      errors.add(date_field, I18n.t("errors.messages.dateformat", date: date))
    end
  end

  property :duration, predicate: ::RDF::Vocab::EBUCore.duration, multiple: false do |index|
    index.as :stored_sortable
  end
  property :avalon_resource_type, predicate: Avalon::RDFVocab::MediaObject.avalon_resource_type, multiple: true do |index|
    index.as :symbol
  end
  property :avalon_publisher, predicate: Avalon::RDFVocab::MediaObject.avalon_publisher, multiple: false do |index|
    index.as :stored_sortable
  end
  property :avalon_uploader, predicate: Avalon::RDFVocab::MediaObject.avalon_uploader, multiple: false do |index|
    index.as :stored_sortable
  end
  property :identifier, predicate: ::RDF::Vocab::Identifiers.local, multiple: true do |index|
    index.as :symbol
  end
  property :comment, predicate: ::RDF::Vocab::EBUCore.comments, multiple: true do |index|
    index.as :stored_searchable
  end

  ordered_aggregation :master_files, class_name: 'MasterFile', through: :list_source
  # ordered_aggregation gives you accessors media_obj.master_files and media_obj.ordered_master_files
  #  and methods for master_files: first, last, [index], =, <<, +=, delete(mf)
  #  and methods for ordered_master_files: first, last, [index], =, <<, +=, insert_at(index,mf), delete(mf), delete_at(index)
  indexed_ordered_aggregation :master_files

  accepts_nested_attributes_for :master_files, :allow_destroy => true

  def published?
    !avalon_publisher.blank?
  end

  def destroy
    # attempt to stop the matterhorn processing job
    self.master_files.each(&:destroy)
    self.master_files.clear
    Bookmark.where(document_id: self.id).destroy_all
    super
  end

  alias_method :'_collection=', :'collection='

  # This requires the MediaObject having an actual id
  def collection= co
    old_collection = self.collection
    self._collection= co
    self.governing_policies.delete(old_collection) if old_collection
    self.governing_policies += [co]
    if self.new_record?
      self.hidden = co.default_hidden
      self.visibility = co.default_visibility
      self.read_users = co.default_read_users.to_a
      self.read_groups = co.default_read_groups.to_a + self.read_groups #Make sure to include any groups added by visibility
    end
  end

  # Sets the publication status. To unpublish an object set it to nil or
  # omit the status which will default to unpublished. This makes the act
  # of publishing _explicit_ instead of an accidental side effect.
  def publish!(user_key)
    self.avalon_publisher = user_key.blank? ? nil : user_key
    save!
  end

  def finished_processing?
    self.master_files.all?{ |master_file| master_file.finished_processing? }
  end

  def set_duration!
    self.duration = calculate_duration.to_s
  end

  def missing_attributes
    @missing_attributes ||= {}
  end

  def report_missing_attributes
    missing_attributes.each_pair { |a,m| errors.add a, m }
  end

  def set_media_types!
    mime_types = master_files.reject {|mf| mf.file_location.blank? }.collect { |mf|
      Rack::Mime.mime_type(File.extname(mf.file_location))
    }.uniq
    self.format = mime_types.empty? ? nil : mime_types
  end

  def set_resource_types!
    self.avalon_resource_type = master_files.reject {|mf| mf.file_format.blank? }.collect{ |mf|
      case mf.file_format
      when 'Moving image'
        'moving image'
      when 'Sound'
        'sound recording'
      else
        mf.file_format.downcase
      end
    }.uniq
  end

  def update_dependent_properties!
    self.set_duration!
    self.set_media_types!
    self.set_resource_types!
  end

  def all_comments
    comment.sort + ordered_master_files.to_a.compact.collect do |mf|
      mf.comment.reject(&:blank?).collect do |c|
        mf.display_title.present? ? "[#{mf.display_title}] #{c}" : c
      end.sort
    end.flatten.uniq
  end

  def section_labels
    all_labels = master_files.collect{|mf|mf.structural_metadata_labels << mf.title}
    all_labels.flatten.uniq.compact
  end

  # Gets all physical descriptions from master files and returns a uniq array
  # @return [Array<String>] A unique list of all physical descriptions for the media object
  def section_physical_descriptions
    all_pds = []
    self.master_files.each do |master_file|
      all_pds += Array(master_file.physical_description) unless master_file.physical_description.nil?
    end
    all_pds.uniq
  end

  def to_solr
    super.tap do |solr_doc|
      solr_doc[ActiveFedora.index_field_mapper.solr_name("workflow_published", :facetable, type: :string)] = published? ? 'Published' : 'Unpublished'
      solr_doc[ActiveFedora.index_field_mapper.solr_name("collection", :symbol, type: :string)] = collection.name if collection.present?
      solr_doc[ActiveFedora.index_field_mapper.solr_name("unit", :symbol, type: :string)] = collection.unit if collection.present?
      solr_doc['read_access_virtual_group_ssim'] = virtual_read_groups + leases('external').map(&:inherited_read_groups).flatten
      solr_doc['read_access_ip_group_ssim'] = collect_ips_for_index(ip_read_groups + leases('ip').map(&:inherited_read_groups).flatten)
      solr_doc[Hydra.config.permissions.read.group] ||= []
      solr_doc[Hydra.config.permissions.read.group] += solr_doc['read_access_ip_group_ssim']
      solr_doc["title_ssort"] = self.title
      solr_doc["creator_ssort"] = Array(self.creator).join(', ')
      solr_doc["date_digitized_sim"] = master_files.collect {|mf| mf.date_digitized }.compact.map {|t| Time.parse(t).strftime "%F" }
      solr_doc["date_ingested_sim"] = self.create_date.strftime "%F" if self.create_date.present?
      #include identifiers for parts
      solr_doc["other_identifier_sim"] +=  master_files.collect {|mf| mf.identifier.to_a }.flatten
      #include labels for parts and their structural metadata
      solr_doc['section_id_ssim'] = ordered_master_file_ids
      solr_doc["section_label_tesim"] = section_labels
      solr_doc['section_physical_description_ssim'] = section_physical_descriptions
      solr_doc['avalon_resource_type_ssim'] = self.avalon_resource_type.map(&:titleize)
      solr_doc['identifier_ssim'] = self.identifier.map(&:downcase)
      solr_doc['all_comments_sim'] = all_comments
      #Add all searchable fields to the all_text_timv field
      all_text_values = []
      all_text_values << solr_doc["title_tesi"]
      all_text_values << solr_doc["creator_ssim"]
      all_text_values << solr_doc["contributor_sim"]
      all_text_values << solr_doc["unit_ssim"]
      all_text_values << solr_doc["collection_ssim"]
      all_text_values << solr_doc["summary_ssi"]
      all_text_values << solr_doc["publisher_sim"]
      all_text_values << solr_doc["subject_topic_sim"]
      all_text_values << solr_doc["subject_geographic_sim"]
      all_text_values << solr_doc["subject_temporal_sim"]
      all_text_values << solr_doc["genre_sim"]
      all_text_values << solr_doc["language_sim"]
      all_text_values << solr_doc["physical_description_sim"]
      all_text_values << solr_doc["date_sim"]
      all_text_values << solr_doc["notes_sim"]
      all_text_values << solr_doc["table_of_contents_sim"]
      all_text_values << solr_doc["other_identifier_sim"]
      solr_doc["all_text_timv"] = all_text_values.flatten
      solr_doc.each_pair { |k,v| solr_doc[k] = v.is_a?(Array) ? v.select { |e| e =~ /\S/ } : v }
    end
  end

  def as_json(options={})
    {
      id: id,
      title: title,
      collection: collection.name,
      unit: collection.unit,
      main_contributors: creator,
      publication_date: date_created,
      published_by: avalon_publisher,
      published: published?,
      summary: abstract,
      visibility: visibility,
      read_groups: read_groups
    }.merge(to_ingest_api_hash(options.fetch(:include_structure, false)))
  end

  # Other validation to consider adding into future iterations is the ability to
  # validate against a known controlled vocabulary. This one will take some thought
  # and research as opposed to being able to just throw something together in an ad hoc
  # manner

  def assign_id!
    self.id = assign_id if self.id.blank?
  end

  def update_permalink
    ensure_permalink!
    true
  end

  def update_dependent_permalinks_job
    UpdateDependentPermalinksJob.perform_later(self.id)
  end

  def update_dependent_permalinks
    self.master_files.each do |master_file|
      begin
      	updated = master_file.ensure_permalink!
      	master_file.save( validate: false ) if updated
      rescue
      	# no-op
      	# Save is called (uncharacteristically) during a destroy.
      end
    end
  end

  def _remove_bookmarks
    Bookmark.where(document_id: self.id).each do |b|
      b.destroy if ( !User.exists? b.user_id ) or ( Ability.new( User.find b.user_id ).cannot? :read, self )
    end
  end

  def remove_bookmarks
    self._remove_bookmarks
  end

  def leases(scope=:all)
    governing_policies.select { |gp| gp.is_a?(Lease) and (scope == :all or gp.lease_type == scope) }
  end

  # @return [Array<MediaObject>, Array<MediaObject>] A list of all succesfully merged and a list of failed media objects
  def merge!(media_objects)
    mergeds = []
    faileds = []
    media_objects.dup.each do |mo|
      begin
        # TODO: mass assignment may speed things up
        mo.ordered_master_files.to_a.dup.each { |mf| mf.media_object = self }
        mo.reload.destroy!

        mergeds << mo
      rescue StandardError => e
        mo.errors.add(:base, "MediaObject #{mo.id} failed to merge successfully: #{e.full_message}")
        faileds << mo
      end
    end
    [mergeds, faileds]
  end

  def access_text
    actors = []
    if visibility == "public"
      actors << "the public"
    else
      actors << "collection staff" if visibility == "private"
      actors << "specific users" if read_users.any? || leases('user').any?

      if visibility == "restricted"
        actors << "logged-in users"
      elsif virtual_read_groups.any? || local_read_groups.any? || leases('external').any? || leases('local').any?
        actors << "users in specific groups"
      end

      actors << "users in specific IP Ranges" if ip_read_groups.any? || leases('ip').any?
    end

    "This item is accessible by: #{actors.join(', ')}."
  end

  private

    def calculate_duration
      self.master_files.map{|mf| mf.duration.to_i }.compact.sum
    end

    def collect_ips_for_index ip_strings
      ips = ip_strings.collect do |ip|
        addr = IPAddr.new(ip) rescue next
        addr.to_range.map(&:to_s)
      end
      ips.flatten.compact.uniq || []
    end

end
