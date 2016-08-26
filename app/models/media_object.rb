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
class MediaObject < ActiveFedora::Base
  include Hydra::AccessControls::Permissions
  include Hidden
  include VirtualGroups
  include ActiveFedora::Associations
  include MediaObjectMods
  include Avalon::Workflow::WorkflowModelMixin
  include Permalink
  require 'avalon/controlled_vocabulary'

  include Kaminari::ActiveFedoraModelExtension

  has_and_belongs_to_many :governing_policies, class_name: 'ActiveFedora::Base', predicate: ActiveFedora::RDF::ProjectHydra.isGovernedBy
  belongs_to :collection, class_name: 'Admin::Collection', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isMemberOfCollection

  after_create :after_create
  before_save :update_dependent_properties!
  before_save :update_permalink, if: Proc.new { |mo| mo.persisted? && mo.published? }
  after_save :update_dependent_permalinks, if: Proc.new { |mo| mo.persisted? && mo.published? }
  after_save :remove_bookmarks

  # Call custom validation methods to ensure that required fields are present and
  # that preferred controlled vocabulary standards are used

  # Guarantees that the record is minimally complete - ie that within the descriptive
  # metadata the title, creator, date of creation, and identifier fields are not
  # blank. Since identifier is set automatically we only need to worry about creator,
  # title, and date of creation.

  validates :title, presence: true
  validate  :validate_language
  validates :date_issued, presence: true
  validate  :report_missing_attributes
  validates :collection, presence: true
  validates :governing_policies, presence: true
  validate  :validate_related_items
  validate  :validate_dates
  validate  :validate_note_type

  def validate_note_type
    Array(note).each{|i|errors.add(:note, "Note type (#{i[0]}) not in controlled vocabulary") unless ModsDocument::NOTE_TYPES.keys.include? i[0] }
  end

  def validate_language
    Array(language).each{|i|errors.add(:language, "Language not recognized (#{i[:code]})") unless LanguageTerm::map[i[:code]] }
  end

  def validate_related_items
    Array(related_item_url).each{|i|errors.add(:related_item_url, "Bad URL") unless i[:url] =~ URI::regexp(%w(http https))}
  end

  def validate_dates
    [:date_created, :date_issued, :copyright_date].each do |d|
      if self.send(d).present? && Date.edtf(self.send(d)).nil?
        errors.add(d, I18n.t("errors.messages.dateformat", date: self.send(d)))
      end
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
    index.as :facetable
  end

  ordered_aggregation :master_files, class_name: 'MasterFile', through: :list_source #, has_member_relation: ActiveFedora::RDF::PCDMTerms.hasMember
  # ordered_aggregation gives you accessors media_obj.master_files and media_obj.ordered_master_files
  #  and methods for master_files (an array): first, last, [index], =, <<, +=, delete(mf)
  #  and methods for ordered_master_files (an array): first, last, [index], =, <<, +=, insert_at(index,mf), delete(mf), delete_at(index)

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

  # This requires the MediaObject having an actual pid
  def collection= co
    old_collection = self.collection
    self._collection= co
    self.governing_policies += [co]
    self.governing_policies.delete(old_collection)
    if (self.read_groups + self.read_users + self.discover_groups + self.discover_users).empty?
      # TODO: Fix the next line
      # self.rightsMetadata.content = co.defaultRights.content unless co.nil?
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
      solr_doc[Solrizer.default_field_mapper.solr_name("workflow_published", :facetable, type: :string)] = published? ? 'Published' : 'Unpublished'
      solr_doc[Solrizer.default_field_mapper.solr_name("collection", :symbol, type: :string)] = collection.name if collection.present?
      solr_doc[Solrizer.default_field_mapper.solr_name("unit", :symbol, type: :string)] = collection.unit if collection.present?
      solr_doc['read_access_virtual_group_ssim'] = virtual_read_groups
      solr_doc['read_access_ip_group_ssim'] = collect_ips_for_index(ip_read_groups)
      solr_doc[Hydra.config.permissions.read.group] ||= []
      solr_doc[Hydra.config.permissions.read.group] += solr_doc['read_access_ip_group_ssim']
      solr_doc["title_ssort"] = self.title
      solr_doc["creator_ssort"] = Array(self.creator).join(', ')
      solr_doc["date_digitized_sim"] = master_files.collect {|mf| mf.date_digitized }.compact.map {|t| Time.parse(t).strftime "%F" }
      solr_doc["date_ingested_sim"] = self.create_date.strftime "%F"
      #include identifiers for parts
      solr_doc["other_identifier_sim"] +=  master_files.collect {|mf| mf.identifier }.flatten
      #include labels for parts and their structural metadata
      solr_doc["section_label_tesim"] = section_labels
      solr_doc['section_physical_description_ssim'] = section_physical_descriptions

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
      main_contributors: creator,
      publication_date: date_created,
      published_by: avalon_publisher,
      published: published?,
      summary: abstract
    }
  end

  # Other validation to consider adding into future iterations is the ability to
  # validate against a known controlled vocabulary. This one will take some thought
  # and research as opposed to being able to just throw something together in an ad hoc
  # manner

  class << self
    def access_control_bulk documents, params
      errors = []
      successes = []
      documents.each do |id|
        media_object = self.find(id)
        media_object.hidden = params[:hidden] if !params[:hidden].nil?
        media_object.visibility = params[:visibility] unless params[:visibility].blank?
        # Limited access stuff
        ["group", "class", "user", "ipaddress"].each do |title|
          if params["submit_add_#{title}"].present?
            begin_time = params["add_#{title}_begin"].blank? ? nil : params["add_#{title}_begin"]
            end_time = params["add_#{title}_end"].blank? ? nil : params["add_#{title}_end"]
            create_lease = begin_time.present? || end_time.present?

            if params[title].present?
              val = params[title].strip
              if title=='user'
                if create_lease
                  begin
                    media_object.governing_policies += [ Lease.create(begin_time: begin_time, end_time: end_time, read_users: [val]) ]
                  rescue Exception => e
                    errors += [media_object]
                  end
                else
                  media_object.read_users += [val]
                end
              elsif title=='ipaddress'
                if ( IPAddr.new(val) rescue false )
                  if create_lease
                    begin
                      media_object.governing_policies += [ Lease.create(begin_time: begin_time, end_time: end_time, read_groups: [val]) ]
                    rescue Exception => e
                      errors += [media_object]
                    end
                  else
                    media_object.read_groups += [val]
                  end
                else
                  context[:error] = "IP Address #{val} is invalid. Valid examples: 124.124.10.10, 124.124.0.0/16, 124.124.0.0/255.255.0.0"
                end
              else
                if create_lease
                  begin
                    media_object.governing_policies += [ Lease.create(begin_time: begin_time, end_time: end_time, read_groups: [val]) ]
                  rescue Exception => e
                    errors += [media_object]
                  end
                else
                  media_object.read_groups += [val]
                end
              end
            end
          end
          if params["submit_remove_#{title}"].present?
            if params[title].present?
              if ["group", "class", "ipaddress"].include? title
                media_object.read_groups -= [params[title]]
                media_object.governing_policies.each do |policy|
                  if policy.class==Lease && policy.read_groups.include?(params[title])
                    media_object.governing_policies.delete policy
                    policy.destroy
                  end
                end
              else
                media_object.read_users -= [params[title]]
                media_object.governing_policies.each do |policy|
                  if policy.class==Lease && policy.read_users.include?(params[title])
                    media_object.governing_policies.delete policy
                    policy.destroy
                  end
                end
              end
            end
          end
        end
        if errors.empty? && media_object.save
          successes += [media_object]
        else
          errors += [media_object]
        end
      end
      return successes, errors
    end
    handle_asynchronously :access_control_bulk

    def update_status_bulk documents, user_key, params
      errors = []
      successes = []
      status = params['action']
      documents.each do |id|
        media_object = self.find(id)
        case status
        when 'publish'
          media_object.publish!(user_key)
          # additional save to set permalink
          if media_object.save
            successes += [media_object]
          else
            errors += [media_object]
          end
        when 'unpublish'
          if media_object.publish!(nil)
            successes += [media_object]
          else
            errors += [media_object]
          end
        end
      end
      return successes, errors
    end
    handle_asynchronously :update_status_bulk

    def delete_bulk documents, params
      errors = []
      successes = []
      documents.each do |id|
        media_object = self.find(id)
        if media_object.destroy
          successes += [media_object]
        else
          errors += [media_object]
        end
      end
      return successes, errors
    end
    handle_asynchronously :delete_bulk

    def move_bulk documents, params
      collection = Admin::Collection.find( params[:target_collection_id] )
      errors = []
      successes = []
      documents.each do |id|
        media_object = self.find(id)
        media_object.collection = collection
        if media_object.save
          successes += [media_object]
        else
          errors += [media_object]
        end
      end
      return successes, errors
    end
    handle_asynchronously :move_bulk

  end

  def update_permalink
    ensure_permalink!
    true
  end

  class << self
    def update_dependent_permalinks id
      mo = self.find(id)
      mo._update_dependent_permalinks
    end
    handle_asynchronously :update_dependent_permalinks
  end

  def _update_dependent_permalinks
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

  def update_dependent_permalinks
    self.class.update_dependent_permalinks self.id
  end

  def _remove_bookmarks
    Bookmark.where(document_id: self.id).each do |b|
      b.destroy if ( !User.exists? b.user_id ) or ( Ability.new( User.find b.user_id ).cannot? :read, self )
    end
  end

  def remove_bookmarks
    self._remove_bookmarks
  end

  private

    def after_create
      self.identifier += [ id ]
      save
    end

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
