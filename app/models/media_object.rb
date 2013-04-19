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

#require 'hydra/rights_metadata'

class MediaObject < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods
  include ActiveFedora::Associations
  include Hydra::ModelMixins::RightsMetadata
  include Avalon::Workflow::WorkflowModelMixin

  # has_relationship "parts", :has_part
  has_many :parts, :class_name=>'MasterFile', :property=>:is_part_of

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
  
  # Call custom validation methods to ensure that required fields are present and
  # that preferred controlled vocabulary standards are used
  
  # Guarantees that the record is minimally complete - ie that within the descriptive
  # metadata the title, creator, date of creation, and identifier fields are not 
  # blank. Since identifier is set automatically we only need to worry about creator,
  # title, and date of creation.

  validates :title, :presence_with_full_error_message => true
  validates :creator, :presence_with_full_error_message => true
  validates :date_issued, :presence_with_full_error_message => true
  validate  :report_missing_attributes

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
    :collection => :collection,
    :geographic_subject => :geographic_subject,
    :temporal_subject => :temporal_subject,
    :topical_subject => :topical_subject,
    :collection => :collection
    }
  end

  
  delegate :avalon_uploader, to: :DC, at: [:creator], unique: true
  delegate :avalon_publisher, to: :DC, at: [:publisher], unique: true
  # Delegate variables to expose them for the forms
  delegate :title, to: :descMetadata, at: [:main_title], unique: true
  delegate :alternative_title, to: :descMetadata, at: [:alternative_title]
  delegate :translated_title, to: :descMetadata, at: [:translated_title]
  delegate :uniform_title, to: :descMetadata, at: [:uniform_title]
  delegate :statement_of_responsibility, to: :descMetadata, at: [:statement_of_responsibility], unique: true
  delegate :creator, to: :descMetadata, at: [:creator]
  delegate :date_created, to: :descMetadata, at: [:date_created], unique: true
  delegate :date_issued, to: :descMetadata, at: [:date_issued], unique: true
  delegate :copyright_date, to: :descMetadata, at: [:copyright_date], unique: true
  delegate :abstract, to: :descMetadata, at: [:abstract], unique: true
  delegate :note, to: :descMetadata, at: [:note]
  delegate :format, to: :descMetadata, at: [:media_type], unique: true
  # Additional descriptive metadata
  delegate :contributor, to: :descMetadata, at: [:contributor]
  delegate :publisher, to: :descMetadata, at: [:publisher]
  delegate :genre, to: :descMetadata, at: [:genre]
  delegate :subject, to: :descMetadata, at: [:topical_subject]
  delegate :related_item, to: :descMetadata, at: [:related_item_id]
  delegate :collection, to: :descMetadata, at: [:collection]

  delegate :geographic_subject, to: :descMetadata, at: [:geographic_subject]
  delegate :temporal_subject, to: :descMetadata, at: [:temporal_subject]
  delegate :topical_subject, to: :descMetadata, at: [:topical_subject]
  
  has_metadata name:'displayMetadata', :type =>  ActiveFedora::SimpleDatastream do |sds|
    sds.field :duration, :string
  end

  has_metadata name:'sectionsMetadata', :type =>  ActiveFedora::SimpleDatastream do |sds|
    sds.field :section_pid, :string
  end

  delegate_to 'displayMetadata', [:duration], unique: true
  delegate_to 'sectionsMetadata', [:section_pid]

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

  # Sets the publication status. To unpublish an object set it to nil or
  # omit the status which will default to unpublished. This makes the act
  # of publishing _explicit_ instead of an accidental side effect.
  def publish!(user_key)
    self.avalon_publisher = user_key.blank? ? nil : user_key 
    self.save(validate: false)
    
    logger.debug "<< User key is #{user_key} >>"
    logger.debug "<< Avalon publisher is now #{avalon_publisher} >>"
  end

  def finished_processing?
    self.parts.all?{ |master_file| master_file.finished_processing? }
  end

  def populate_duration!
    self.duration = calculate_duration.to_s
  end

  def access
    logger.debug "<< ACCESS >>"
    logger.debug "<< #{self.read_groups} >>"
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
      logger.debug "<< Updating #{k} >>"
      logger.debug "<< #{v} >>"

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
          logger.debug "<< Entry : #{entry} >>"
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
    logger.debug "Updating #{attribute.inspect} with value #{value.inspect} and attributes #{attributes.inspect}"
    metadata_attribute = find_metadata_attribute(attribute)
    metadata_attribute_value = value

    if metadata_attribute.nil?
      missing_attributes[attribute] = "Metadata attribute `#{attribute}' not found"
      logger.debug "Metadata attribute was nil, attribute is: #{attribute}"
      return false
    else
      values = Array(value).select { |v| not v.blank? }
      descMetadata.find_by_terms( metadata_attribute ).each &:remove
      if descMetadata.template_registry.has_node_type?( metadata_attribute )
        values.each_with_index do |val, i|
          logger.debug "<< Adding node #{metadata_attribute}[#{i}] >>"
          logger.debug("descMetadata.add_child_node(descMetadata.ng_xml.root, #{metadata_attribute.to_sym.inspect}, #{val.inspect}, #{(attributes[i]||{}).inspect})")
          descMetadata.add_child_node(descMetadata.ng_xml.root, metadata_attribute, val, (attributes[i]||{}))
        end
        #end
      elsif descMetadata.respond_to?("add_#{metadata_attribute}")
        values.each_with_index do |val, i|
          logger.debug("descMetadata.add_#{metadata_attribute}(#{val.inspect}, #{attributes[i].inspect})")
          descMetadata.send("add_#{metadata_attribute}", val, (attributes[i] || {}))
        end;
      else
        # Put in a placeholder so that the inserted nodes go into the right part of the
        # document. Afterwards take it out again - unless it does not have a template
        # in which case this is all that needs to be done
        if self.respond_to?("#{metadata_attribute}=")
          logger.debug "<< Calling delegated method #{metadata_attribute} >>"
          self.send("#{metadata_attribute}=", values)
        else
          logger.debug "<< Calling descMetadata method #{metadata_attribute} >>"
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
    solr_doc[:created_by_facet] = self.DC.creator
    solr_doc[:hidden_b] = hidden?
    solr_doc[:duration_display] = self.duration
    solr_doc[:workflow_published_facet] = published? ? 'Published' : 'Unpublished'
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
end
