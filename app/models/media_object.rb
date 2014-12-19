# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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
  
  # has_relationship "parts", :has_part
  has_many :parts, :class_name=>'MasterFile', :property=>:is_part_of
  belongs_to :governing_policy, :class_name=>'Admin::Collection', :property=>:is_governed_by
  belongs_to :collection, :class_name=>'Admin::Collection', :property=>:is_member_of_collection

  has_metadata name: "descMetadata", type: ModsDocument	

  after_create :after_create
  
  # Before saving put the pieces into the right order and validate to make sure that
  # there are no syntactic errors
  before_save 'descMetadata.ensure_identifier_exists!'
  before_save 'descMetadata.update_change_date!'
  before_save 'descMetadata.reorder_elements!'
  before_save 'descMetadata.remove_empty_nodes!'
  before_save 'update_permalink_and_dependents'

  has_model_version 'R3'

  # Call custom validation methods to ensure that required fields are present and
  # that preferred controlled vocabulary standards are used
  
  # Guarantees that the record is minimally complete - ie that within the descriptive
  # metadata the title, creator, date of creation, and identifier fields are not 
  # blank. Since identifier is set automatically we only need to worry about creator,
  # title, and date of creation.

  validates :title, :presence => true
  validate  :validate_creator
  validate  :validate_language
  validates :date_issued, :presence => true
  validate  :report_missing_attributes
  validates :collection, presence: true
  validates :governing_policy, presence: true
  validate  :validate_related_items

  def validate_language
    Array(language).each{|i|errors.add(:language, "Language not recognized (#{i[:code]})") unless LanguageTerm::map[i[:code]] }
  end

  def validate_related_items
    Array(related_item_url).each{|i|errors.add(:related_item_url, "Bad URL") unless i[:url] =~ URI::regexp(%w(http https))}
  end

  def validate_creator
    if Array(creator).select { |c| c.present? }.empty?
      errors.add(:creator, I18n.t("errors.messages.blank"))
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
    :bibliographic_id_label => :bibliographic_id_label,
    :language => :language,
    :terms_of_use => :terms_of_use,
    :physical_description => :physical_description,
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
  has_attributes :physical_description, datastream: :descMetadata, at: [:physical_description], multiple: false
  
  has_metadata name:'displayMetadata', :type =>  ActiveFedora::SimpleDatastream do |sds|
    sds.field :duration, :string
  end

  has_metadata name:'sectionsMetadata', :type =>  ActiveFedora::SimpleDatastream do |sds|
    sds.field :section_pid, :string
  end

  has_attributes :duration, datastream: :displayMetadata, multiple: false
  has_attributes :section_pid, datastream: :sectionsMetadata, multiple: true

  accepts_nested_attributes_for :parts, :allow_destroy => true

  IDENTIFIER_TYPES =  Avalon::ControlledVocabulary.find_by_name(:identifier_types) || {"other" => "Local"}

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
  end

  def parts_with_order
    self.section_pid.map{|pid| MasterFile.find(pid)}
  end

  def section_pid=( pids )
    self.sectionsMetadata.find_by_terms(:section_pid).each &:remove
    self.sectionsMetadata.update_values(['section_pid'] => pids)
  end

  alias_method :'_collection=', :'collection='

  # This requires the MediaObject having an actual pid
  def collection= co
    # TODO: Removes existing association

    self._collection= co
    self.governing_policy = co
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
    if values[:bibliographic_id]
      values[:bibliographic_id] = [[Array(values.delete(:bibliographic_id_label)).first || IDENTIFIER_TYPES.keys[0], Array(values[:bibliographic_id]).first]]
    end
    if values[:related_item_url] and values[:related_item_label]
        values[:related_item_url] = values[:related_item_url].zip(values.delete(:related_item_label))
    end
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
        if v.first.is_a?(Hash)
          vals = []
          attrs = []
        
          v.each do |entry|
            vals << entry[:value]
            attrs << entry[:attributes]
          end
          update_attribute_in_metadata(k, vals, attrs)
        else
          update_attribute_in_metadata(k, Array(v))
        end
      rescue Exception => msg
        missing_attributes[k.to_sym] = msg.to_s
      end
    end
  end

  def bibliographic_id
    descMetadata.identifier.present? ? [descMetadata.identifier.type.first,descMetadata.identifier.first] : nil
  end
  def related_item_url
    descMetadata.related_item_url.zip(descMetadata.related_item_label).map{|a|{url: a[0],label: a[1]}}
  end
  def language
    descMetadata.language.code.zip(descMetadata.language.text).map{|a|{code: a[0],text: a[1]}}
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
      values = Array(value).select { |v| not v.blank? }
      descMetadata.find_by_terms( metadata_attribute ).each &:remove
      if descMetadata.template_registry.has_node_type?( metadata_attribute )
        values.each_with_index do |val, i|
          descMetadata.add_child_node(descMetadata.ng_xml.root, metadata_attribute, val, (attributes[i]||{}))
        end
        #end
      elsif descMetadata.respond_to?("add_#{metadata_attribute}")
        values.each_with_index do |val, i|
          descMetadata.send("add_#{metadata_attribute}", val, (attributes[i] || {}))
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
    begin
      mime_types = parts.collect { |mf| 
        mf.file_location.nil? ? nil : Rack::Mime.mime_type(File.extname(mf.file_location)) 
      }.compact.uniq
      
      resource_type_to_formatted_text_map = {'Moving image' => 'moving image', 'Sound' => 'sound recording'}
      resource_types = self.parts.collect{|master_file| resource_type_to_formatted_text_map[master_file.file_format] }.uniq

      mime_types = nil if mime_types.empty?
      resource_types = nil if resource_types.empty?

      update_attribute_in_metadata(:media_type, mime_types)
      update_attribute_in_metadata(:resource_type, resource_types)

    rescue Exception => e
      logger.warn "Error in set_media_types!: #{e}"
    end
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
    solr_doc["dc_creator_tesim"] = self.creator
    solr_doc["dc_publisher_tesim"] = self.publisher
    solr_doc["title_ssort"] = self.title
    solr_doc["creator_ssort"] = Array(self.creator).join(', ')
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
    all_text_values << solr_doc["physical_description_si"]
    solr_doc["all_text_timv"] = all_text_values.flatten
    return solr_doc
  end

  # Other validation to consider adding into future iterations is the ability to
  # validate against a known controlled vocabulary. This one will take some thought
  # and research as opposed to being able to just throw something together in an ad hoc
  # manner

  private
    def after_create
      self.DC.identifier = pid
      save
    end
    
    def calculate_duration
      self.parts.map{|mf| mf.duration.to_i }.compact.sum
    end

    def update_permalink_and_dependents
      if self.persisted? && self.published?
        ensure_permalink!
        self.parts.each do |master_file| 
          begin
            master_file.ensure_permalink!
            master_file.save( validate: false )
          rescue
          	# no-op
          	# Save is called (uncharacteristically) during a destroy.
          end
        end

        unless self.descMetadata.permalink.include? self.permalink 
          self.descMetadata.permalink = self.permalink
        end
      end

      true
    end

end
