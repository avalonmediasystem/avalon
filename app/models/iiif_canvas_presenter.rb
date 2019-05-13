class IiifCanvasPresenter
  attr_reader :master_file, :stream_info
  attr_accessor :media_fragment

  def initialize(master_file:, stream_info:, media_fragment: nil)
    @master_file = master_file
    @stream_info = stream_info
    @media_fragment = media_fragment
  end

  delegate :derivative_ids, :id, to: :master_file

  def to_s
    master_file.display_title
  end

  def range
    structure_ng_xml.root.blank? ? simple_iiif_range : structure_to_iiif_range
  end

  # @return [IIIFManifest::V3::DisplayContent] the display content required by the manifest builder.
  def display_content
    master_file.is_video? ? video_content : audio_content
  end

  private

    def video_content
      # @see https://github.com/samvera-labs/iiif_manifest
      stream_urls.collect { |label, url| video_display_content(url, label) }
    end

    def video_display_content(url, label = '')
      IIIFManifest::V3::DisplayContent.new(url,
                                           label: label,
                                           width: master_file.width.to_i,
                                           height: master_file.height.to_i,
                                           duration: stream_info[:duration],
                                           type: 'Video')
    end

    def audio_content
      stream_urls.collect { |label, url| audio_display_content(url, label) }
    end

    def audio_display_content(url, label = '')
      IIIFManifest::V3::DisplayContent.new(url,
                                           label: label,
                                           duration: stream_info[:duration],
                                           type: 'Sound')
    end

    def stream_urls
      stream_info[:stream_hls].collect do |d|
        [d[:quality], d[:url]]
      end
    end

    def simple_iiif_range
      # TODO: embed_title?
      IiifManifestRange.new(
        label: { '@none'.to_sym => [stream_info[:embed_title]] },
        items: [
          IiifCanvasPresenter.new(master_file: master_file, stream_info: stream_info, media_fragment: 't=0,')
        ]
      )
    end

    def structure_to_iiif_range
      div_to_iiif_range(structure_ng_xml.root)
    end

    def div_to_iiif_range(div_node)
      items = div_node.children.select(&:element?).collect do |node|
        if node.name == "Div"
          div_to_iiif_range(node)
        elsif node.name == "Span"
          span_to_iiif_range(node)
        end
      end

      # if a non-leaf node has no valid "Div" or "Span" children, then it would become empty range node containing no canvas
      # raise an exception here as this error shall have been caught and handled by the parser and shall never happen here
      raise Nokogiri::XML::SyntaxError, "Empty root or Div node: #{div_node[:label]}" if items.empty?

      IiifManifestRange.new(
        label: { '@none' => [div_node[:label]] },
        items: items
      )
    end

    def span_to_iiif_range(span_node)
      fragment = "t=#{parse_hour_min_sec(span_node[:begin])},#{parse_hour_min_sec(span_node[:end])}"
      IiifManifestRange.new(
        label: { '@none' => [span_node[:label]] },
        items: [
          IiifCanvasPresenter.new(master_file: master_file, stream_info: stream_info, media_fragment: fragment)
        ]
      )
    end

    FLOAT_PATTERN = Regexp.new(/^\d+([.]\d*)?$/).freeze

    def parse_hour_min_sec(s)
      return nil if s.nil?
      smh = s.split(':').reverse
      (0..2).each do |i|
        # Use Regexp.match? when we drop ruby 2.3 support
        smh[i] = smh[i] =~ FLOAT_PATTERN ? Float(smh[i]) : 0
      end
      smh[0] + (60 * smh[1]) + (3600 * smh[2])
    end

    # Note that the method returns empty Nokogiri Document instead of nil when structure_tesim doesn't exist or is empty.
    def structure_ng_xml
      # TODO: The XML parser should handle invalid XML files, for ex, if a non-leaf node has no valid "Div" or "Span" children,
      # in which case SyntaxError shall be prompted to the user during file upload.
      # This can be done by defining some XML schema to require that at least one Div/Span child node exists
      # under root or each Div node, otherwise Nokogiri::XML parser will report error, and raise exception here.
      @structure_ng_xml ||= (s = master_file.structuralMetadata.content).nil? ? Nokogiri::XML(nil) : Nokogiri::XML(s)
    end
end
