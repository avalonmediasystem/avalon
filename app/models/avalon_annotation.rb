# TODO: Class level yardoc
class AvalonAnnotation < ActiveAnnotations::Annotation
  alias_method :comment, :content
  alias_method :comment=, :content=

  # TODO: Turn me on when label is implemented
  # alias_method :title, :label
  # alias_method :title=, :label=

  # Intialize an annotation with the start and end time set to the lengths of the master_file by default
  # @param [MasterFile] :source the master file referenced by the annotation
  def initialize(source: master_file)
    super
    @master_file = master_file
    selector_default!
    # title_default!
    self
  end

  # Mixs in in Avalon specific information from the master_file to a rdf annonation prior and creates a solr document
  # @return [Hash] a hash capable of submission to solr
  def to_solr
    init_masterfile if @master_file.nil?
    solr_hash = {}
    # TODO: User Key via parsing of User URI
    # TODO: Turn me on when mbk has label implemented
    # solr_hash[:title_ssi] = title
    solr_hash[:master_file_uri_ssi] = @master_file.rdf_uri
    solr_hash[:master_file_rdf_type_ssi] = @master_file.rdf_type
    solr_hash[:start_time_fsi] = start_time
    solr_hash[:end_time_fsi] = end_time
    solr_hash[:mediafragment_uri_ssi] = mediafragment_uri
    solr_hash[:comment_ssi] = comment unless comment.nil?
    solr_hash[:referenced_source_type_ssi] = 'MasterFile'
    solr_hash[:reference_type] = 'MediaFragment'
    solr_hash
  end

  # Sets the default selector to a start time of 0 and an end time of the master file length
  def selector_default!
    self.start_time = 0
    self.end_time = @master_file.duration || 1
  end

  # Set the default title to be the label of the master_file
  def title_default!
    #TODO: Make sure mbklein has used .title for the accessor here
    self.title = @master_file.label
  end

  # Sets the class variable @master_file by finding the master referenced in the source uri
  def init_masterfile
    @master_file = MasterFile.find(source.split('/').last)
  end

  # Calcuates the mediafragment_uri based on either the internal fragment value or start and end times
  # @return [String] the uri with time bounding
  def mediafragment_uri
    rdf_uri + "?#{internal.fragment_value}"
  rescue
    rdf_uri + "?t#{start_time},#{end_time}"
  end
end
