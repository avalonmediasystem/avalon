class MetadataFieldComponent < Blacklight::MetadataFieldComponent
  def initialize(field:, layout: nil, show: false, view_type: nil)
    super
    @layout = MetadataFieldLayoutComponent
  end
end
