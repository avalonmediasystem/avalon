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
  include Avalon::AccessControls::Hidden
  include Avalon::AccessControls::VirtualGroups
  include Hydra::ModelMethods
  include ActiveFedora::Associations
  include Avalon::Workflow::WorkflowModelMixin
  include VersionableModel
  include Permalink
  require 'avalon/controlled_vocabulary'

  include Kaminari::ActiveFedoraModelExtension

  # has_relationship "parts", :has_part
  has_many :parts, :class_name=>'MasterFile', :property=>:is_part_of
  has_and_belongs_to_many :governing_policies, :class_name=>'ActiveFedora::Base', :property=>:is_governed_by
  belongs_to :collection, :class_name=>'Admin::Collection', :property=>:is_member_of_collection

  has_metadata name: "descMetadata", type: ModsDocument

  after_create :after_create
  before_save :normalize_desc_metadata!
  before_save :update_dependent_properties!
  before_save :update_permalink, if: Proc.new { |mo| mo.persisted? && mo.published? }
  after_save :update_dependent_permalinks, if: Proc.new { |mo| mo.persisted? && mo.published? }
  after_save :remove_bookmarks


  has_model_version 'R4'

  # Call custom validation methods to ensure that required fields are present and
  # that preferred controlled vocabulary standards are used

  # Guarantees that the record is minimally complete - ie that within the descriptive
  # metadata the title, creator, date of creation, and identifier fields are not
  # blank. Since identifier is set automatically we only need to worry about creator,
  # title, and date of creation.

  validates :title, :presence => true
  validate  :validate_language
  validates :date_issued, :presence => true
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

  # this method returns a hash: class attribute -> metadata attribute
  # this is useful for decoupling the metdata from the view
  def klass_attribute_to_metadata_attribute_map
    {
    :avalon_uploader => :creator,
    :avalon_publisher => :publisher,
    :title => :main_title,
    :alternative_title => :alternative_title,
    :translated_title => :translated_title,
    :uniform_title => :uniform_title,
    :statement_of_responsibility => :statement_of_responsibility,
    :creator => :creator,
    :date_created => :date_created,
    :date_issued => :date_issued,
    :copyright_date => :copyright_date,
    :abstract => :abstract,
    :note => :note,
    :format => :media_type,
    :contributor => :contributor,
    :publisher => :publisher,
    :genre => :genre,
    :subject => :topical_subject,
    :related_item_url => :related_item_url,
    :geographic_subject => :geographic_subject,
    :temporal_subject => :temporal_subject,
    :topical_subject => :topical_subject,
    :bibliographic_id => :bibliographic_id,
    :language => :language,
    :terms_of_use => :terms_of_use,
    :table_of_contents => :table_of_contents,
    :physical_description => :physical_description,
    :other_identifier => :other_identifier,
    :record_identifier => :record_identifier,
    }
  end


  has_attributes :avalon_uploader, datastream: :DC, at: [:creator], multiple: false
  has_attributes :avalon_publisher, datastream: :DC, at: [:publisher], multiple: false
  # Delegate variables to expose them for the forms
  has_attributes :title, datastream: :descMetadata, at: [:main_title], multiple: false
  has_attributes :alternative_title, datastream: :descMetadata, at: [:alternative_title], multiple: true
  has_attributes :translated_title, datastream: :descMetadata, at: [:translated_title], multiple: true
  has_attributes :uniform_title, datastream: :descMetadata, at: [:uniform_title], multiple: true
  has_attributes :statement_of_responsibility, datastream: :descMetadata, at: [:statement_of_responsibility], multiple: false
  has_attributes :creator, datastream: :descMetadata, at: [:creator], multiple: true
  has_attributes :date_created, datastream: :descMetadata, at: [:date_created], multiple: false
  has_attributes :date_issued, datastream: :descMetadata, at: [:date_issued], multiple: false
  has_attributes :copyright_date, datastream: :descMetadata, at: [:copyright_date], multiple: false
  has_attributes :abstract, datastream: :descMetadata, at: [:abstract], multiple: false
  has_attributes :note, datastream: :descMetadata, at: [:note], multiple: true
  has_attributes :format, datastream: :descMetadata, at: [:media_type], multiple: false
  has_attributes :resource_type, datastream: :descMetadata, at: [:resource_type], multiple: true
  # Additional descriptive metadata
  has_attributes :contributor, datastream: :descMetadata, at: [:contributor], multiple: true
  has_attributes :publisher, datastream: :descMetadata, at: [:publisher], multiple: true
  has_attributes :genre, datastream: :descMetadata, at: [:genre], multiple: true
  has_attributes :subject, datastream: :descMetadata, at: [:topical_subject], multiple: true
  has_attributes :related_item_url, datastream: :descMetadata, at: [:related_item_url], multiple: true

  has_attributes :geographic_subject, datastream: :descMetadata, at: [:geographic_subject], multiple: true
  has_attributes :temporal_subject, datastream: :descMetadata, at: [:temporal_subject], multiple: true
  has_attributes :topical_subject, datastream: :descMetadata, at: [:topical_subject], multiple: true
  has_attributes :bibliographic_id, datastream: :descMetadata, at: [:bibliographic_id], multiple: false

  has_attributes :language, datastream: :descMetadata, at: [:language], multiple: true
  has_attributes :terms_of_use, datastream: :descMetadata, at: [:terms_of_use], multiple: false
  has_attributes :table_of_contents, datastream: :descMetadata, at: [:table_of_contents], multiple: true
  has_attributes :physical_description, datastream: :descMetadata, at: [:physical_description], multiple: true
  has_attributes :other_identifier, datastream: :descMetadata, at: [:other_identifier], multiple: true
  has_attributes :record_identifier, datastream: :descMetadata, at: [:record_identifier], multiple: true

  has_metadata name:'displayMetadata', :type =>  ActiveFedora::SimpleDatastream do |sds|
    sds.field :duration, :string
    sds.field :avalon_resource_type, :string
  end

  has_metadata name:'sectionsMetadata', :type =>  ActiveFedora::SimpleDatastream do |sds|
    sds.field :section_pid, :string
  end

  has_attributes :duration, datastream: :displayMetadata, multiple: false
  has_attributes :avalon_resource_type, datastream: :displayMetadata, multiple: true
  has_attributes :section_pid, datastream: :sectionsMetadata, multiple: true

  accepts_nested_attributes_for :parts, :allow_destroy => true

  def published?
    not self.avalon_publisher.blank?
  end

  def destroy
    # attempt to stop the matterhorn processing job
    self.parts.each(&:destroy)
    self.parts.clear
    Bookmark.where(document_id: self.pid).destroy_all
    super
  end

  # Removes one or many MasterFiles from parts_with_order
  def parts_with_order_remove part
    self.parts_with_order = self.parts_with_order.reject{|master_file| master_file.pid == part.pid }
  end

  def parts_with_order= master_files
    self.section_pid = master_files.map(&:pid)
    self.sectionsMetadata.save if self.persisted?
    self.section_pid
  end

  def parts_with_order(opts = {})
    pids_with_order = section_pid
    if !!opts[:load_from_solr]
      return [] if pids_with_order.empty?
      pid_list = pids_with_order.uniq.map { |pid| RSolr.solr_escape(pid) }.join ' OR '
      solr_results = ActiveFedora::SolrService.query("id\:(#{pid_list})", rows: pids_with_order.length)
      mfs = ActiveFedora::SolrService.reify_solr_results(solr_results, load_from_solr: true)
      pids_with_order.map { |pid| mfs.find { |mf| mf.pid == pid }}
    else
      pids_with_order.map{|pid| MasterFile.find(pid)}
    end
  end

  def _section_pid
    self.sectionsMetadata.get_values(:section_pid)
  end

  def section_pid
    ordered_pids = self._section_pid
    missing_from_order = self.part_ids - ordered_pids
    missing_parts = ordered_pids - self.part_ids
    ordered_pids + missing_from_order - missing_parts
  end

  def section_pid=( pids )
    self.section_pid_will_change!
    self.sectionsMetadata.find_by_terms(:section_pid).each &:remove
    self.sectionsMetadata.update_values(['section_pid'] => pids)
  end

  alias_method :'_collection=', :'collection='

  # This requires the MediaObject having an actual pid
  def collection= co
    # TODO: Removes existing association

    self._collection= co
    self.governing_policies -= [self.governing_policies.to_a.find {|gp| gp.is_a? Admin::Collection }]
    self.governing_policies += [co]
    if (self.read_groups + self.read_users + self.discover_groups + self.discover_users).empty?
      self.rightsMetadata.content = co.defaultRights.content unless co.nil?
    end
  end

  # Sets the publication status. To unpublish an object set it to nil or
  # omit the status which will default to unpublished. This makes the act
  # of publishing _explicit_ instead of an accidental side effect.
  def publish!(user_key)
    self.avalon_publisher = user_key.blank? ? nil : user_key
    self.save(validate: false)
  end

  def finished_processing?
    self.parts.all?{ |master_file| master_file.finished_processing? }
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

  def find_metadata_attribute(attribute)
    metadata_attribute = klass_attribute_to_metadata_attribute_map[ attribute.to_sym ]
    if metadata_attribute.nil? and descMetadata.class.terminology.terms.has_key?(attribute.to_sym)
      metadata_attribute = attribute.to_sym
    end
    metadata_attribute
  end

  def update_datastream(datastream = :descMetadata, values = {})
    missing_attributes.clear
    # Special case the identifiers and their types
    if values[:bibliographic_id].present? and values[:bibliographic_id_label].present?
      values[:bibliographic_id] = {value: values[:bibliographic_id], attributes: values[:bibliographic_id_label]}
    end
    values.delete(:bibliographic_id_label)
    if values[:related_item_url].present? and values[:related_item_label].present?
        values[:related_item_url] = values[:related_item_url].zip(values[:related_item_label])
    end
    values.delete(:related_item_label)
    if values[:note].present? and values[:note_type].present?
      values[:note]=values[:note].zip(values[:note_type]).map{|v| {value: v[0], attributes: v[1]}}
    end
    values.delete(:note_type)
    if values[:other_identifier].present? and values[:other_identifier_type].present?
      values[:other_identifier]=values[:other_identifier].zip(values[:other_identifier_type]).map{|v| {value: v[0], attributes: v[1]}}
    end
    values.delete(:other_identifier_type)

    values.each do |k, v|
      # First remove all blank attributes in arrays
      v.keep_if { |item| not item.blank? } if v.instance_of?(Array)

      # Peek at the first value in the array. If it is a Hash then unpack it into two
      # arrays before you pass everything off to the update_attributes method so that
      # the markup is composed properly
      #
      # This does not feel right but is just a first pass. Maybe the use of NOM rather
      # than OM will mitigate the need for such tricks
      begin
        if v.is_a?(Hash)
          update_attribute_in_metadata(k, v[:value], v[:attributes])
        elsif v.is_a?(Array) and v.first.is_a?(Hash)
          vals = []
          attrs = []

          v.each do |entry|
            vals << entry[:value]
            attrs << entry[:attributes]
          end
          update_attribute_in_metadata(k, vals, attrs)
        else
          update_attribute_in_metadata(k, v)
        end
      rescue Exception => msg
        missing_attributes[k.to_sym] = msg.to_s
      end
    end
  end

  def bibliographic_id
    descMetadata.bibliographic_id.present? ? [descMetadata.bibliographic_id.source.first,descMetadata.bibliographic_id.first] : nil
  end
  def related_item_url
    descMetadata.related_item_url.zip(descMetadata.related_item_label).map{|a|{url: a[0],label: a[1]}}
  end
  def language
    descMetadata.language.code.zip(descMetadata.language.text).map{|a|{code: a[0],text: a[1]}}
  end
  def note
    descMetadata.note.present? ? descMetadata.note.type.zip(descMetadata.note) : nil
  end
  def other_identifier
    descMetadata.other_identifier.present? ? descMetadata.other_identifier.type.zip(descMetadata.other_identifier) : nil
  end


  # This method is one way in that it accepts class attributes and
  # maps them to metadata attributes.
  def update_attribute_in_metadata(attribute, value = [], attributes = [])
    # class attributes should be decoupled from metadata attributes
    # class attributes are displayed in the view and posted to the server
    metadata_attribute = find_metadata_attribute(attribute)
    metadata_attribute_value = value
    if metadata_attribute.nil?
      missing_attributes[attribute] = "Metadata attribute '#{attribute}' not found"
      return false
    else
      values = if self.class.multiple?(attribute)
        Array(value).select { |v| not v.blank? }
      elsif Array(value).length==1
        Array(value).first
      else
        value
      end
      descMetadata.find_by_terms( metadata_attribute ).each &:remove
      if descMetadata.template_registry.has_node_type?( metadata_attribute )
        Array(values).each_with_index do |val, i|
          descMetadata.add_child_node(descMetadata.ng_xml.root, metadata_attribute, val, (Array(attributes)[i]||{}))
        end
        #end
      elsif descMetadata.respond_to?("add_#{metadata_attribute}")
        Array(values).each_with_index do |val, i|
          descMetadata.send("add_#{metadata_attribute}", val, (Array(attributes)[i] || {}))
        end;
      else
        # Put in a placeholder so that the inserted nodes go into the right part of the
        # document. Afterwards take it out again - unless it does not have a template
        # in which case this is all that needs to be done
        if self.respond_to?("#{metadata_attribute}=")
          self.send("#{metadata_attribute}=", values)
        else
          descMetadata.send("#{metadata_attribute}=", values)
        end
      end
    end
  end

  def set_media_types!
    mime_types = parts.reject {|mf| mf.file_location.blank? }.collect { |mf|
      Rack::Mime.mime_type(File.extname(mf.file_location))
    }.uniq
    update_attribute_in_metadata(:format, mime_types.empty? ? nil : mime_types)
  end

  def set_resource_types!
    self.avalon_resource_type = parts.reject {|mf| mf.file_format.blank? }.collect{ |mf|
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
    all_labels = parts.collect{|mf|mf.structural_metadata_labels << mf.label}
    all_labels.flatten.uniq.compact
  end

  # Gets all physical descriptions from master files and returns a uniq array
  # @return [Array<String>] A unique list of all physical descriptions for the media object
  def section_physical_descriptions
    all_pds = []
    self.parts.each do |master_file|
      all_pds += master_file.descMetadata.physical_description unless master_file.descMetadata.physical_description.nil?
    end
    all_pds.uniq
  end

  def to_solr(solr_doc = Hash.new, opts = {})
    solr_doc = super(solr_doc, opts)
    solr_doc[Solrizer.default_field_mapper.solr_name("created_by", :facetable, type: :string)] = self.DC.creator
    solr_doc[Solrizer.default_field_mapper.solr_name("duration", :displayable, type: :string)] = self.duration
    solr_doc[Solrizer.default_field_mapper.solr_name("workflow_published", :facetable, type: :string)] = published? ? 'Published' : 'Unpublished'
    solr_doc[Solrizer.default_field_mapper.solr_name("collection", :symbol, type: :string)] = collection.name if collection.present?
    solr_doc[Solrizer.default_field_mapper.solr_name("unit", :symbol, type: :string)] = collection.unit if collection.present?
    indexer = Solrizer::Descriptor.new(:string, :stored, :indexed, :multivalued)
    solr_doc[Solrizer.default_field_mapper.solr_name("read_access_virtual_group", indexer)] = virtual_read_groups
    solr_doc[Solrizer.default_field_mapper.solr_name("read_access_ip_group", indexer)] = collect_ips_for_index(ip_read_groups)
    solr_doc[Hydra.config.permissions.read.group] ||= []
    solr_doc[Hydra.config.permissions.read.group] += solr_doc[Solrizer.default_field_mapper.solr_name("read_access_ip_group", indexer)]
    solr_doc["dc_creator_tesim"] = self.creator
    solr_doc["dc_publisher_tesim"] = self.publisher
    solr_doc["title_ssort"] = self.title
    solr_doc["creator_ssort"] = Array(self.creator).join(', ')
    solr_doc["date_digitized_sim"] = parts.collect {|mf| mf.date_digitized }.compact.map {|t| Time.parse(t).strftime "%F" }
    solr_doc["date_ingested_sim"] = Time.parse(self.create_date).strftime "%F"
    #include identifiers for parts
    solr_doc["other_identifier_sim"] += parts.collect {|mf| mf.DC.identifier }.flatten
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
    return solr_doc
  end

  def as_json(options={})
    {
      id: pid,
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
    unless self.descMetadata.permalink.include? self.permalink
      self.descMetadata.permalink = self.permalink
    end
  end

  class << self
    def update_dependent_permalinks pid
      mo = self.find(pid)
      mo._update_dependent_permalinks
    end
    handle_asynchronously :update_dependent_permalinks
  end

  def _update_dependent_permalinks
    self.parts.each do |master_file|
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
    self.class.update_dependent_permalinks self.pid
  end

  def _remove_bookmarks
    Bookmark.where(document_id: self.pid).each do |b|
      b.destroy if ( !User.exists? b.user_id ) or ( Ability.new( User.find b.user_id ).cannot? :read, self )
    end
  end

  def remove_bookmarks
    self._remove_bookmarks
  end

  private
    # Put the pieces into the right order and validate to make sure that there are no
    # syntactic errors
    def normalize_desc_metadata!
      descMetadata.ensure_identifier_exists!
      descMetadata.update_change_date!
      descMetadata.reorder_elements!
      descMetadata.remove_empty_nodes!
    end

    def after_create
      self.DC.identifier = pid
      save
    end

    def calculate_duration
      self.parts.map{|mf| mf.duration.to_i }.compact.sum
    end

    def collect_ips_for_index ip_strings
      ips = ip_strings.collect do |ip|
        addr = IPAddr.new(ip) rescue next
        addr.to_range.map(&:to_s)
      end
      ips.flatten.compact.uniq || []
    end

end
