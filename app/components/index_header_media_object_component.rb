class IndexHeaderMediaObjectComponent < Blacklight::DocumentTitleComponent
  def initialize(title = nil, document: nil, presenter: nil, as: :h3, counter: nil, classes: 'index_title document-title-heading col', link_to_document: true, document_component: nil, actions: true)
    super
    @classes += @actions.present? ? " col-sm-9 col-lg-10" : " col-md-12"
  end
end