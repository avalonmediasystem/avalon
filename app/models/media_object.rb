class MediaObject < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods
  include ActiveFedora::Associations
  include Hydra::ModelMixins::RightsMetadata
  include Hydrant::Workflow::WorkflowModelMixin

  # has_relationship "parts", :has_part
  has_many :parts, :class_name=>'MasterFile', :property=>:is_part_of

  has_metadata name: "DC", type: DublinCoreDocument
  has_metadata name: "descMetadata", type: ModsDocument	

  after_create :after_create
  
  # Before saving put the pieces into the right order and validate to make sure that
  # there are no syntactic errors
  before_save 'descMetadata.ensure_identifier_exists!', prepend: true
  before_save 'descMetadata.update_change_date!', prepend: true
  before_save 'descMetadata.reorder_elements!', prepend: true
  
  # Call custom validation methods to ensure that required fields are present and
  # that preferred controlled vocabulary standards are used
  
  # Guarantees that the record is minimally complete - ie that within the descriptive
  # metadata the title, creator, date of creation, and identifier fields are not 
  # blank. Since identifier is set automatically we only need to worry about creator,
  # title, and date of creation.

  validates :title, :presence_with_full_error_message => true
  validates :creator, :presence_with_full_error_message => true
  validates :date_created, :presence_with_full_error_message => true

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
  delegate :creator, to: :descMetadata, at: [:creator], unique: true
  delegate :date_created, to: :descMetadata, at: [:date_created], unique: true
  delegate :date_issued, to: :descMetadata, at: [:date_issued], unique: true
  delegate :copyright_date, to: :descMetadata, at: [:copyright_date], unique: true
  delegate :abstract, to: :descMetadata, at: [:abstract], unique: true
  delegate :note, to: :descMetadata, at: [:note]
  delegate :format, to: :descMetadata, at: [:media_type], unique: true
  # Additional descriptive metadata
  delegate :contributor, to: :descMetadata, at: [:contributor]
  delegate :publisher, to: :descMetadata, at: [:publisher]
  delegate :genre, to: :descMetadata, at: [:genre], unique: true
  delegate :subject, to: :descMetadata, at: [:topical_subject]
  delegate :related_item, to: :descMetadata, at: [:related_item_id]
  delegate :collection, to: :descMetadata, at: [:collection]

  delegate :geographic_subject, to: :descMetadata, at: [:geographic_subject]
  delegate :temporal_subject, to: :descMetadata, at: [:temporal_subject]
  delegate :topical_subject, to: :descMetadata, at: [:topical_subject]
  
  has_metadata name:'displayMetadata', :type =>  ActiveFedora::SimpleDatastream do |sds|
    sds.field :duration, :string
  end

  delegate_to 'displayMetadata', [:duration], unique: true

  accepts_nested_attributes_for :parts, :allow_destroy => true

  def is_published?
    not self.avalon_publisher.blank?
  end

  def publish!( user_key )
    self.avalon_publisher = user_key
    self.save(validate: false)
  end

  def unpublish!
    self.avalon_publisher = nil
    self.save( validate: false)
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
    
    if self.read_groups.empty?
      "private"
    elsif self.read_groups.include? "public"
      "public"
    elsif self.read_groups.include? "registered"
      "restricted" 
    end
  end

  def access= access_level
    if access_level == "public"
      groups = self.read_groups
      groups << 'public'
      groups << 'registered'
      self.read_groups = groups
    elsif access_level == "restricted"
      groups = self.read_groups
      groups.delete 'public'
      groups << 'registered'
      self.read_groups = groups
    else #private
      groups = self.read_groups
      groups.delete 'public'
      groups.delete 'registered'
      self.read_groups = groups
    end
  end

  alias :user_exceptions :read_users
  alias :user_exceptions= :read_users=

  def group_exceptions
    groups = self.read_groups
    groups.delete 'public'
    groups.delete 'registered'
    groups
  end

  def group_exceptions= group_list
    access_level = access
    self.read_groups = []
    self.access = access_level
    groups = self.read_groups
    groups += group_list
    self.read_groups = groups
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

  def update_datastream(datastream = :descMetadata, values = {})
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
    metadata_attribute = klass_attribute_to_metadata_attribute_map[ attribute.to_sym ]
    metadata_attribute_value = value
    if metadata_attribute.nil? and descMetadata.class.terminology.terms.has_key?(attribute.to_sym)
      metadata_attribute = attribute.to_sym
    end

    if metadata_attribute.nil?
      raise "Metadata attribute not found, class attribute: #{attribute}"
      logger.debug "Metadata attribute was nil, attribute is: #{attribute}"
    end

    descMetadata.find_by_terms( metadata_attribute ).each &:remove
    if descMetadata.template_registry.has_node_type?( metadata_attribute )
      Array(value).each_with_index do |val, i|
        logger.debug "<< Adding node #{metadata_attribute}[#{i}] >>"
        logger.debug("descMetadata.add_child_node(descMetadata.ng_xml.root, #{metadata_attribute.to_sym.inspect}, #{val.inspect}, #{(attributes[i]||{}).inspect})")
        descMetadata.add_child_node(descMetadata.ng_xml.root, metadata_attribute, metadata_attribute_value, (attributes[i]||{}))
      end
      #end
    elsif descMetadata.respond_to?("add_#{metadata_attribute}")
      Array(value).each_with_index do |val, i|
        logger.debug("descMetadata.add_#{metadata_attribute}(#{val.inspect}, #{attributes[i].inspect})")
        descMetadata.send("add_#{metadata_attribute}", val, (attributes[i] || {}))
      end;
    else
      # Put in a placeholder so that the inserted nodes go into the right part of the
      # document. Afterwards take it out again - unless it does not have a template
      # in which case this is all that needs to be done
      if self.respond_to?("#{metadata_attribute}=", value)
        logger.debug "<< Calling delegated method #{metadata_attribute} >>"
        self.send("#{metadata_attribute}=", value)
      else
        logger.debug "<< Calling descMetadata method #{metadata_attribute} >>"
        descMetadata.send("#{metadata_attribute}=", value)
      end
    end
  end
  
  def to_solr(solr_doc = Hash.new, opts = {})
    super(solr_doc, opts)
    solr_doc[:created_by_facet] = self.DC.creator
    solr_doc[:hidden_b] = hidden?
    solr_doc[:duration_display] = self.duration
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

