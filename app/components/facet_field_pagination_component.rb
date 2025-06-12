class FacetFieldPaginationComponent < Blacklight::FacetFieldPaginationComponent
  def initialize(**kwargs)
    super
    @span_button_classes = 'btn btn-primary'
  end
end