class IndexMetadataMediaObjectComponent < Blacklight::DocumentMetadataComponent
  # @param fields [Enumerable<Blacklight::FieldPresenter>] Document field presenters
  # rubocop:disable Metrics/ParameterLists
  def initialize(**kwargs)
    super
    @classes += %w[col-md-12 col-lg-8]
    @field_layout ||= MetadataFieldLayoutComponent
  end

  def before_render
    return unless fields

    @fields.each do |field|
      @document = field.document
      with_field(component: field.component, field: field, show: @show, view_type: @view_type, layout: @field_layout)
    end
  end
end
