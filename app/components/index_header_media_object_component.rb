class IndexHeaderMediaObjectComponent < Blacklight::DocumentTitleComponent
  def initialize(title = nil, document: nil, presenter: nil, as: :h3, counter: nil, classes: 'index_title document-title-heading col', link_to_document: true, document_component: nil, actions: true)
    super
    @classes += @actions.present? ? " col-sm-9 col-lg-10" : " col-md-12"
  end

  # Override to add test-id
  def title
    if @link_to_document
      helpers.link_to_document presenter.document, @title.presence || content.presence, counter: @counter, itemprop: 'name', data: { testid: "browse-document-title-#{presenter.document.id}" }
    else
      content_tag('span', @title.presence || content.presence || presenter.heading, itemprop: 'name')
    end
  end
end
