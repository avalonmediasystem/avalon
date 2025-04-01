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
  include MediaObjectBehavior
  require 'avalon/controlled_vocabulary'

  include Kaminari::ActiveFedoraModelExtension

  has_and_belongs_to_many :governing_policies, class_name: 'ActiveFedora::Base', predicate: ActiveFedora::RDF::ProjectHydra.isGovernedBy
  belongs_to :collection, class_name: 'Admin::Collection', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection

  before_save :update_dependent_properties!, prepend: true
  before_save :update_permalink, if: Proc.new { |mo| mo.persisted? && mo.published? }, prepend: true
  before_save :assign_id!, prepend: true

  after_find do
    # Force loading of section_ids from list_source
    self.section_ids if self.section_list.nil?
  end

  # Persist to master_files only on save to avoid changes to master_files auto-saving and making things out of sync
  # This might be able to be removed along with the ordered_aggregation to rely purely on section_list and the relationship
  # on the MasterFile model
  # Have to handle create specially otherwise will attempt to associate prior to having an id
  around_create do |_, block|
    block.call
    # Saving again will force running through the before_save callback that should do the actual work
    self.save!(validate: false) unless self.master_file_ids.sort == self.section_ids.sort
  end
  before_save do
    unless self.new_record? || self.master_file_ids.sort == self.section_ids.sort
      # Instead of using the master_files association writer manually set the hasPart triples on the media object
      # The association writer in ActiveFedora fetches all of the master files including associated resources (via find)
      # before writing the master file ids to the proxy ActiveFedora::IndirectContainer subresource id/master_files.
      # This approach requires some overrides of ActiveFedora to fill in some missing functionality.
      # These overrides have been appended to config/initializers/active_fedora_general.rb
      self.attribute_will_change! :master_files
      self.resource.set_value(::RDF::Vocab::DC.hasPart, self.section_ids.collect {|id| ::RDF::Resource.new(MasterFile.id_to_uri(id))})
    end
  end

  after_save :update_dependent_permalinks_job, if: Proc.new { |mo| mo.persisted? && mo.published? }
  after_save :remove_bookmarks
  after_update_index :enqueue_long_indexing

  # Call custom validation methods to ensure that required fields are present and
  # that preferred controlled vocabulary standards are used

  # Guarantees that the record is minimally complete - ie that within the descriptive
  # metadata the title, creator, date of creation, and identifier fields are not
  # blank. Since identifier is set automatically we only need to worry about creator,
  # title, and date of creation.

  validates :collection, presence: true
  # validates :governing_policies, presence: true if Proc.new { |mo| mo.changes["governing_policy_ids"].empty? }

  validates :title, presence: true, if: :resource_description_active?
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
  property :lending_period, predicate: ::RDF::Vocab::SCHEMA.eligibleDuration, multiple: false do |index|
    index.as :stored_sortable
  end

  #TODO: get rid of all ordered_* and indexed_* references, after everything is migrated then convert from `ordered_aggregation` to `has_many`
  # OR possibly remove the master_files relationship entirely?
  ordered_aggregation :master_files, class_name: 'MasterFile', through: :list_source
  # ordered_aggregation gives you accessors media_obj.master_files and media_obj.ordered_master_files
  #  and methods for master_files: first, last, [index], =, <<, +=, delete(mf)
  #  and methods for ordered_master_files: first, last, [index], =, <<, +=, insert_at(index,mf), delete(mf), delete_at(index)
  indexed_ordered_aggregation :master_files

  accepts_nested_attributes_for :master_files, :allow_destroy => true

  property :section_list, predicate: Avalon::RDFVocab::MediaObject.section_list, multiple: false do |index|
    index.as :symbol
  end

  def section_ids= ids
    self.section_list = ids.to_json
    @sections = nil
    @section_ids = ids
  end

  def sections= mfs
    self.section_ids = mfs.map(&:id)
    @sections = mfs
  end

  def sections
    @sections ||= MasterFile.find(self.section_ids)
  end

  def section_ids
    return @section_ids if @section_ids

    # Do migration
    self.section_ids = self.ordered_master_file_ids.compact if self.section_list.nil?

    return [] if self.section_list.nil?
    @section_ids = JSON.parse(self.section_list)
  end
  
  def published?
    !avalon_publisher.blank?
  end

  def destroy
    # attempt to stop the matterhorn processing job
    self.sections.each(&:stop_processing!)
    # avoid calling destroy on each section since it calls save on parent media object
    self.sections.each(&:delete)
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
      self.lending_period = co.default_lending_period
    end
  end

  # Sets the publication status. To unpublish an object set it to nil or
  # omit the status which will default to unpublished. This makes the act
  # of publishing _explicit_ instead of an accidental side effect.
  def publish!(user_key, validate: true)
    self.avalon_publisher = user_key.blank? ? nil : user_key
    if validate
      save!
    else
      raise "Save failed" unless save(validate: false)
    end
  end

  def finished_processing?
    self.sections.all? { |section| section.finished_processing? }
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
    mime_types = section_solr_docs.reject { |section| section["file_location_ssi"].blank? }.collect do |section|
      Rack::Mime.mime_type(File.extname(section["file_location_ssi"]))
    end.uniq
    self.format = mime_types.empty? ? nil : mime_types
  end

  def set_resource_types!
    self.avalon_resource_type = section_solr_docs.reject { |section| section["file_format_ssi"].blank? }.collect do |section|
      case section["file_format_ssi"]
      when 'Moving image'
        'moving image'
      when 'Sound'
        'sound recording'
      else
        section.file_format.downcase
      end
    end.uniq
  end

  def update_dependent_properties!
    @section_docs = nil
    self.set_duration!
    self.set_media_types!
    self.set_resource_types!
  end

  def all_comments
    comment.sort + sections.compact.collect do |section|
      section.comment.reject(&:blank?).collect do |c|
        section.display_title.present? ? "[#{section.display_title}] #{c}" : c
      end.sort
    end.flatten.uniq
  end

  def section_labels
    all_labels = sections.collect{ |section| section.structural_metadata_labels << section.title}
    all_labels.flatten.uniq.compact
  end

  # Gets all physical descriptions from master files and returns a uniq array
  # @return [Array<String>] A unique list of all physical descriptions for the media object
  def section_physical_descriptions
    all_pds = []
    self.sections.each do |section|
      all_pds += Array(section.physical_description) unless section.physical_description.nil?
    end
    all_pds.uniq
  end

  # All fields that need to iterate over the master files do in this new method
  # using a copy of the master file solr doc to avoid having to fetch them all from fedora
  # this is probably okay since this is just aggregating the values already in the master file solr docs

  def fill_in_solr_fields_that_need_sections(solr_doc)
    solr_doc["other_identifier_sim"] +=  sections.collect {|section| section.identifier.to_a }.flatten
    solr_doc["date_digitized_ssim"] = sections.collect {|section| section.date_digitized }.compact.map {|t| Time.parse(t).strftime "%F" }
    solr_doc["has_captions_bsi"] = has_captions
    solr_doc["has_transcripts_bsi"] = has_transcripts
    solr_doc["section_label_tesim"] = section_labels
    solr_doc['section_physical_description_ssim'] = section_physical_descriptions
    solr_doc['all_comments_ssim'] = all_comments
  end

  def fill_in_solr_fields_needing_leases(solr_doc)
    solr_doc['read_access_virtual_group_ssim'] = virtual_read_groups + leases('external').map(&:inherited_read_groups).flatten
    solr_doc['read_access_ip_group_ssim'] = collect_ips_for_index(ip_read_groups + leases('ip').map(&:inherited_read_groups).flatten)
    solr_doc[Hydra.config.permissions.read.group] ||= []
    solr_doc[Hydra.config.permissions.read.group] += solr_doc['read_access_ip_group_ssim']
  end

  # Enqueue background job to do a full indexing including more costly fields that read from children
  def enqueue_long_indexing
    MediaObjectIndexingJob.perform_later(id)
  end

  def to_solr(include_child_fields: false)
    descMetadata.to_solr(super).tap do |solr_doc|
      solr_doc[ActiveFedora.index_field_mapper.solr_name("workflow_published", :facetable, type: :string)] = published? ? 'Published' : 'Unpublished'
      solr_doc[ActiveFedora.index_field_mapper.solr_name("collection", :symbol, type: :string)] = collection.name if collection.present?
      solr_doc[ActiveFedora.index_field_mapper.solr_name("unit", :symbol, type: :string)] = collection.unit if collection.present?
      solr_doc["title_ssort"] = self.title
      solr_doc["creator_ssort"] = Array(self.creator).join(', ')
      solr_doc["date_ingested_ssim"] = self.create_date.strftime "%F" if self.create_date.present?
      solr_doc['avalon_resource_type_ssim'] = self.avalon_resource_type
      # Downcasing identifier allows for case-insensitive searching but has the side effect of causing all identiiers to be lower case in JSON responses
      solr_doc['identifier_ssim'] = self.identifier.map(&:downcase)
      solr_doc['note_ssm'] = self.note.collect { |n| n.to_json }
      solr_doc['other_identifier_ssm'] = self.other_identifier.collect { |oi| oi.to_json }
      solr_doc['related_item_url_ssm'] = self.related_item_url.collect { |r| r.to_json }
      solr_doc['section_id_ssim'] = section_ids
      if include_child_fields
        fill_in_solr_fields_that_need_sections(solr_doc)
        fill_in_solr_fields_needing_leases(solr_doc)
      elsif id.present? # avoid error in test suite
        # Fill in other identifier so these values aren't stripped from the solr doc while waiting for the background job
        mf_docs = ActiveFedora::SolrService.query("isPartOf_ssim:#{id}", rows: 100_000)
        solr_doc["other_identifier_sim"] +=  mf_docs.collect { |h| h['identifier_ssim'] }.flatten
      end

      #Add all searchable fields to the all_text_timv field
      all_text_values = []
      all_text_values << solr_doc["title_tesi"]
      all_text_values << solr_doc["creator_ssim"]
      all_text_values << solr_doc["contributor_ssim"]
      all_text_values << solr_doc["unit_ssim"]
      all_text_values << solr_doc["collection_ssim"]
      all_text_values << solr_doc["abstract_ssi"]
      all_text_values << solr_doc["publisher_ssim"]
      all_text_values << solr_doc["topical_subject_ssim"]
      all_text_values << solr_doc["geographic_subject_ssim"]
      all_text_values << solr_doc["temporal_subject_ssim"]
      all_text_values << solr_doc["genre_ssim"]
      all_text_values << solr_doc["language_ssim"]
      all_text_values << solr_doc["physical_description_ssim"]
      all_text_values << solr_doc["series_ssim"]
      all_text_values << solr_doc["date_sim"]
      all_text_values << solr_doc["notes_sim"]
      all_text_values << solr_doc["table_of_contents_ssim"]
      all_text_values << solr_doc["other_identifier_sim"]
      all_text_values << solr_doc["bibliographic_id_ssi"]
      solr_doc["all_text_timv"] = all_text_values.flatten
      solr_doc.each_pair { |k,v| solr_doc[k] = v.is_a?(Array) ? v.select { |e| e =~ /\S/ } : v }
    end
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
    self.sections.each do |section|
      begin
        updated = section.ensure_permalink!
        section.save( validate: false ) if updated
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
        mo.sections.each { |section| section.media_object = self }
        mo.reload.destroy!

        mergeds << mo
      rescue StandardError => e
        mo.errors.add(:base, "MediaObject #{mo.id} failed to merge successfully: #{e.full_message}")
        faileds << mo
      end
    end
    [mergeds, faileds]
  end

  alias_method :'_lending_period', :'lending_period'
  def lending_period
    self._lending_period || collection&.default_lending_period
  end

  # Override to reset memoized fields
  def reload
    @section_docs = nil
    @sections = nil
    @section_ids = nil
    super
  end

  def self.autocomplete(query, id)
    return if id.blank?
    collection_unit = SpeedyAF::Proxy::MediaObject.find(id).collection.unit
    # To take advantage of solr automagically escaping characters the query has to be in single quotes.
    # This runs counter to ruby's string interpolation which requires the string to be in double quotes.
    # We can get around this by using the format_string construction.
    solr_query = { q: 'unit_ssim:"%{collection_unit}"' % { collection_unit: collection_unit } }
    query_params = {
      fl: ["series_ssim"],
      facet: "on",
      "facet.field" => "series_ssim",
      "facet.contains" => query.to_s,
      "facet.contains.ignoreCase" => "true",
      "facet.exists" => "true",
      "facet.limit" => "-1",
      rows: 0
    }
    param = solr_query.merge(query_params)

    # The search results are returned as an array alternating the returned facet and the count of that facet,
    # e.g. ['Series', 1, 'Test', 1]. We safely retrieve the facet by converting the array to a hash of key = facet,
    # value = count and then only looking at the keys.
    search_array = ActiveFedora::SolrService.instance.conn.get('select', params: param).dig("facet_counts", "facet_fields", "series_ssim").each_slice(2).to_h.keys

    search_array.map { |value| { id: value, display: value } }
  end

  private

    def section_solr_docs
      # Explicitly query for each id in section_ids instead of the reverse to ensure consistency
      # This may skip master file objects which claim to be a part of this media object but are not
      # in the section_list
      return [] unless section_ids.present?
      query = "id:" + section_ids.join(" id:")
      @section_docs ||= ActiveFedora::SolrService.query(query, rows: 100_000)
    end

    def calculate_duration
      section_solr_docs.collect { |h| h['duration_ssi'].to_i }.compact.sum
    end

    def collect_ips_for_index ip_strings
      ips = ip_strings.collect do |ip|
        addr = IPAddr.new(ip) rescue next
        addr.to_range.map(&:to_s)
      end
      ips.flatten.compact.uniq || []
    end

    def sections_with_files(tag: '*')
      # TODO: Optimize this into a single solr query?
      section_ids.select { |m| SpeedyAF::Proxy::MasterFile.find(m).supplemental_files(tag: tag).present? }
    end
end
