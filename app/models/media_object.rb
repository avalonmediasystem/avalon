# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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
  include Hydra::ModelMethods
  include ActiveFedora::Associations
  include Avalon::Workflow::WorkflowModelMixin
  include Hydra::ModelMixins::Migratable
  include Permalink

  # has_relationship "parts", :has_part
  has_many :parts, :class_name=>'MasterFile', :property=>:is_part_of
  belongs_to :governing_policy, :class_name=>'Admin::Collection', :property=>:is_governed_by
  belongs_to :collection, :class_name=>'Admin::Collection', :property=>:is_member_of_collection

  has_metadata name: "DC", type: DublinCoreDocument
  has_metadata name: "descMetadata", type: ModsDocument	

  after_create :after_create
  
  # Before saving put the pieces into the right order and validate to make sure that
  # there are no syntactic errors
  before_save 'set_media_types!'
  before_save 'descMetadata.ensure_identifier_exists!'
  before_save 'descMetadata.update_change_date!'
  before_save 'descMetadata.reorder_elements!'
  before_save 'descMetadata.remove_empty_nodes!'
  before_save { |obj| obj.current_migration = 'R2' }
  before_save { |obj| obj.populate_duration! }

  before_save :update_permalink_and_depenedents
  
  # Call custom validation methods to ensure that required fields are present and
  # that preferred controlled vocabulary standards are used
  
  # Guarantees that the record is minimally complete - ie that within the descriptive
  # metadata the title, creator, date of creation, and identifier fields are not 
  # blank. Since identifier is set automatically we only need to worry about creator,
  # title, and date of creation.

  validates :title, :presence => true
  validate  :validate_creator
  validates :date_issued, :presence => true
  validate  :report_missing_attributes
  validates :collection, presence: true
  validates :governing_policy, presence: true

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
    :related_item => :related_item_id,
    :geographic_subject => :geographic_subject,
    :temporal_subject => :temporal_subject,
    :topical_subject => :topical_subject,
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
  has_attributes :related_item, datastream: :descMetadata, at: [:related_item_id], multiple: true

  has_attributes :geographic_subject, datastream: :descMetadata, at: [:geographic_subject], multiple: true
  has_attributes :temporal_subject, datastream: :descMetadata, at: [:temporal_subject], multiple: true
  has_attributes :topical_subject, datastream: :descMetadata, at: [:topical_subject], multiple: true
  
  has_metadata name:'displayMetadata', :type =>  ActiveFedora::SimpleDatastream do |sds|
    sds.field :duration, :string
  end

  has_metadata name:'sectionsMetadata', :type =>  ActiveFedora::SimpleDatastream do |sds|
    sds.field :section_pid, :string
  end

  has_attributes :duration, datastream: :displayMetadata, multiple: false
  has_attributes :section_pid, datastream: :sectionsMetadata, multiple: true

  accepts_nested_attributes_for :parts, :allow_destroy => true

  def published?
    not self.avalon_publisher.blank?
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
    self.save( validate: false )
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

  def populate_duration!
    self.duration = calculate_duration.to_s
  end

  def access
    if self.read_users.present?
      "limited"
    elsif self.read_groups.empty?
      "private"
    elsif self.read_groups.include? "public"
      "public"
    elsif self.read_groups.include? "registered"
      "restricted" 
    else 
      "limited"
    end
  end

  def access= access_level
    # Preserves group_exceptions when access_level changes to be not limited
    # This is a work-around for the limitation in Hydra: 1 group can't belong to both :read and :exceptions
    if access == "limited" && access_level != access
      self.group_exceptions = read_groups
      self.user_exceptions = read_users
      self.read_users = []
    end

    if access_level == "public"
      self.read_groups = ['public', 'registered'] 
    elsif access_level == "restricted"
      self.read_groups = ['registered'] 
    elsif access_level == "private"
      self.read_groups = []
    else #limited
      # Setting access to "limited" will copy group_exceptions to read_groups
      if access != "limited"
        self.read_groups = group_exceptions
        self.read_users = user_exceptions
      else
        self.read_groups = (read_groups + group_exceptions).uniq
        self.read_users = (read_users + user_exceptions).uniq
      end 
    end
  end

  # user_exceptions and group_exceptions are used to store exceptions info
  # They aren't activated until access is set to limited
  def user_exceptions
    rightsMetadata.individuals.map {|k, v| k if v == 'exceptions'}.compact  
  end

  def user_exceptions= users
    set_entities(:exceptions, :person, users, user_exceptions)
  end

  # Return a list of groups that have exceptions permission
  def group_exceptions
    rightsMetadata.groups.map {|k, v| k if v == 'exceptions'}.compact
  end

  # Grant read permissions to the groups specified. Revokes read permission for all other groups.
  # @param[Array] groups a list of group names
  # @example
  #  r.read_groups= ['one', 'two', 'three']
  #  r.read_groups 
  #  => ['one', 'two', 'three']
  #
  def group_exceptions= groups
    set_entities(:exceptions, :group, groups, group_exceptions)
  end

  # Get those permissions we don't want to change
  # Overrides the one in hydra-access-controls/lib/hydra/model_mixins/rights_metadata.rb
  # to support group_exceptions
  def preserved(type, permission)
    # Always preserves exceptions
    g = Hash[rightsMetadata.quick_search_by_type(type).select {|k, v| v == 'exceptions'}] || {} 

    case permission
    when :exceptions
      # Preserves edit groups/users 
      g.merge! Hash[rightsMetadata.quick_search_by_type(type).select {|k, v| v == 'edit'}]
    when :read
      g.merge! Hash[rightsMetadata.quick_search_by_type(type).select {|k, v| v == 'edit'}]
    when :discover
      g.merge! Hash[rightsMetadata.quick_search_by_type(type).select {|k, v| v == 'discover'}]
    end
    g
  end

  def hidden= value
    groups = self.discover_groups
    if value
      groups << "nobody"
    else
      groups.delete "nobody"
    end
    self.discover_groups = groups.uniq
  end

  def hidden?
    self.discover_groups.include? "nobody"
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
    values.each do |k, v|
      # First remove all blank attributes in arrays
      v.keep_if { |item| not item.blank? } if v.instance_of?(Array)

      # Peek at the first value in the array. If it is a Hash then unpack it into two
      # arrays before you pass everything off to the update_attributes method so that
      # the markup is composed properly
      #
      # This does not feel right but is just a first pass. Maybe the use of NOM rather
      # than OM will mitigate the need for such tricks
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
    end
  end

  # This method is one way in that it accepts class attributes and
  # maps them to metadata attributes.
  def update_attribute_in_metadata(attribute, value = [], attributes = [])
    # class attributes should be decoupled from metadata attributes
    # class attributes are displayed in the view and posted to the server
    metadata_attribute = find_metadata_attribute(attribute)
    metadata_attribute_value = value

    if metadata_attribute.nil?
      missing_attributes[attribute] = "Metadata attribute `#{attribute}' not found"
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

      descMetadata.ensure_root_term_exists!(:physical_description)
      descMetadata.ensure_root_term_exists!(:resource_type)

      descMetadata.find_by_terms(:physical_description, :internet_media_type).remove
      descMetadata.find_by_terms(:resource_type).remove

      descMetadata.update_values([:physical_description, :internet_media_type] => mime_types, [:resource_type] => resource_types)
    rescue Exception => e
      logger.warn "Error in set_media_types!: #{e}"
    end
  end
  
  def to_solr(solr_doc = Hash.new, opts = {})
    super(solr_doc, opts)
    solr_doc[Solrizer.default_field_mapper.solr_name("created_by", :facetable, type: :string)] = self.DC.creator
    solr_doc[Solrizer.default_field_mapper.solr_name("hidden", type: :boolean)] = hidden?
    solr_doc[Solrizer.default_field_mapper.solr_name("duration", :displayable, type: :string)] = self.duration
    solr_doc[Solrizer.default_field_mapper.solr_name("workflow_published", :facetable, type: :string)] = published? ? 'Published' : 'Unpublished'
    solr_doc[Solrizer.default_field_mapper.solr_name("collection", :symbol, type: :string)] = collection.name if collection.present?
    solr_doc[Solrizer.default_field_mapper.solr_name("unit", :symbol, type: :string)] = collection.unit if collection.present?
    #Add all searchable fields to the all_text_timv field
    all_text_values = []
    all_text_values << solr_doc["title_tesim"]
    all_text_values << solr_doc["creator_ssim"]
    all_text_values << solr_doc["contributor_sim"]
    all_text_values << solr_doc["unit_ssim"]
    all_text_values << solr_doc["collection_ssim"]
    all_text_values << solr_doc["summary_ssim"]
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

    def update_permalink_and_depenedents
      updated = create_or_update_permalink( self )
      if updated 
        self.parts.each{|master_file| create_or_update_permalink(master_file) }
      end
    end

end
