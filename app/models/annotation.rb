class Annotation < ActiveRecord::Base
  scope :from_master_file, ->(master_file_id) { where("source_uri LIKE ?", "%#{master_file_id}%") }

  delegate :start_time, :end_time,
           :content, :annotated_by,
           :annotated_at, :source, :label,
           to: :internal

  after_initialize do
    selector_default!
    title_default!
  end

  %i[start_time= end_time= content= annotated_by= annotated_at= source= label=].each do |setter|
    define_method(setter) do |*args|
      internal.send(setter, *args)
      @internal_changed = true
      sync_attributes!
    end
  end

  %i[source_uri= annotation= uuid=].each do |invalid_setter|
    define_method(invalid_setter) do |*args|
      raise NoMethodError, "undefined method `#{invalid_setter}' for #{self}"
    end
  end

  alias_method :title, :label
  alias_method :title=, :label=

  validates :master_file, :title, :start_time, presence: true
  validates :start_time, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: proc { |a| a.max_time },
    message: "must be between 0 and end of section"
  }

  before_save :sync_attributes!
  before_save :sync_annotation!

  def inspect
    internal_attrs = %i[annotated_by annotated_at start_time end_time source content].collect do |attr|
      "#{attr}: #{internal.send(attr).inspect}"
    end
    inspection = (["uuid: #{uuid.inspect}"] + internal_attrs).compact.join(', ')
    hex_id = '%#016x' % (object_id << 1)
    "#<#{self.class}:#{hex_id} #{inspection}>"
  end

  def sync_attributes!
    self[:uuid] = internal.annotation_id.value
    self[:source_uri] = internal.source
    true
  end

  def sync_annotation!
    if @internal_changed
      self[:annotation] = internal.to_jsonld
      @internal_changed = false
    end
    true
  end

  def internal
    if @internal.nil?
      if annotation.nil?
        @internal = RDFAnnotation.new
        self[:annotation] = @internal.to_jsonld
      else
        @internal = RDFAnnotation.from_jsonld(annotation)
      end
    end
    @internal
  end

  def annotation
    sync_annotation!
    self[:annotation]
  end

  def pretty_annotation
    sync_annotation!
    internal.to_jsonld(pretty_json: true)
  end

  # This function determines the max time for a masterfile and its derivatives
  # Used for determining the maximum possible end time for an annotation
  # @return [float] the largest end time or -1 if no durations present
  def max_time
    max = -1
    max = master_file.duration.to_f if master_file.present? && master_file.duration.present?
    if master_file.present?
      master_file.derivatives.each do |derivative|
        max = derivative.duration.to_f if derivative.present? && derivative.duration.present? && derivative.duration.to_f > max
      end
    end
    max
  end

  # Sets the default selector to a start time of 0 and an end time of the master file length
  def selector_default!
    self.start_time = 0 if self.start_time.nil?
  end

  # Set the default title to be the label of the master_file
  def title_default!
    self.title = master_file.embed_title if self.title.nil? && master_file.present?
  end

  def master_file_id
    @master_file_id ||= CGI::unescape(self.source.split('/').last) if self.source
  end

  # Sets the class variable @master_file by finding the master referenced in the source uri
  def master_file
    @master_file ||= SpeedyAF::Proxy::MasterFile.find(master_file_id) if master_file_id
  rescue SpeedyAF::RecordNotFound
    nil
  end

  def master_file=(value)
    @master_file = value
    self.source = @master_file
    @master_file
  end

  # Calcuates the mediafragment_uri based on either the internal fragment value or start and end times
  # @return [String] the uri with time bounding
  def mediafragment_uri
    "#{master_file&.rdf_uri}?#{internal.fragment_value.object}"
  rescue
    "#{master_file&.rdf_uri}?t=#{start_time},#{end_time}"
  end
end
