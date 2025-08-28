class IndexHeaderMediaObjectComponent < Blacklight::DocumentTitleComponent
  include TimeFormattingHelper

  def initialize(**kwargs)
    super
    @classes += @actions.present? ? " col-sm-9 col-lg-10" : " col-md-12"
    @title = search_result_label(presenter.document)
  end

  # Override to add test-id
  def title
    if @link_to_document
      helpers.link_to_document presenter.document, @title.presence || content.presence, counter: @counter, itemprop: 'name', data: { testid: "browse-document-title-#{presenter.document.id}" }
    else
      content_tag('span', @title.presence || content.presence || presenter.heading, itemprop: 'name')
    end
  end

  private

  def search_result_label document
    if document['title_tesi'].present?
      label = truncate(document['title_tesi'], length: 100)
    else
      label = document[:id]
    end

    if document['duration_ssi'].present?
      duration = document['duration_ssi']
      if duration.respond_to?(:to_i) && duration.to_i > 0
        label += " (#{milliseconds_to_formatted_time(duration.to_i, false)})"
      end
    end

    label
  end
end
