class IndexMetadataMediaObjectComponent < Blacklight::DocumentMetadataComponent
  # @param fields [Enumerable<Blacklight::FieldPresenter>] Document field presenters
  # rubocop:disable Metrics/ParameterLists
  def initialize(fields: [], tag: 'dl', classes: %w[document-metadata dl-invert row col-md-12 col-lg-8], show: false, view_type: nil, field_layout: nil, **component_args)
    @fields = fields
    @tag = tag
    @classes = classes
    @show = show
    @view_type = view_type
    @field_layout = field_layout
    @component_args = component_args
  end

  def before_render
    return unless fields

    @fields.each do |field|
      @document = field.document
      with_field(component: field.component, field: field, show: @show, view_type: @view_type, layout: @field_layout)
    end
  end
end