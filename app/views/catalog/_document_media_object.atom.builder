# frozen_string_literal: true

xml.entry do
  xml.title document_presenter(document).heading

  # updated is required, for now we'll just set it to now, sorry
  xml.updated document[:descMetadata_modified_dtsi] || document[:timestamp]

  xml.link    "rel" => "alternate", "type" => "application/json", "href" => media_object_url(document.id, format: :json)
  # add other doc-specific formats, atom only lets us have one per
  # content type, so the first one in the list wins.
  # xml << show_presenter(document).link_rel_alternates(unique: true)

  xml.id media_object_url(document.id)

  if document.to_semantic_values.key? :author
    xml.author { xml.name(document.to_semantic_values[:author].first) }
  end

  with_format(:html) do
    xml.summary "type" => "html" do
      document_component = blacklight_config.view_config(:atom).summary_component
      render document_component.new(document: document_presenter(document), component: :div, show: true)
    end
  end

  #If they asked for a format, give it to them.
  if (params["content_format"] &&
    document.export_formats[params["content_format"].to_sym])

    type = document.export_formats[params["content_format"].to_sym][:content_type]

    xml.content type: type do |content_element|
      data = document.export_as(params["content_format"])

      # encode properly. See:
      # http://tools.ietf.org/html/rfc4287#section-4.1.3.3
      type = type.downcase
      if (type.downcase =~ %r{\+|/xml$})
        # xml, just put it right in
        content_element << data
      elsif (type.downcase =~ %r{text/})
        # text, escape
        content_element.text! data
      else
        #something else, base64 encode it
        content_element << Base64.encode64(data)
      end
    end

  end
end
