# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

class IiifCanvasPresenter
  include IiifSupplementalFileBehavior

  attr_reader :master_file, :stream_info
  attr_accessor :media_fragment

  def initialize(master_file:, stream_info:, media_fragment: nil)
    @master_file = master_file
    @stream_info = stream_info
    @media_fragment = media_fragment
  end

  delegate :derivative_ids, :id, to: :master_file

  def to_s
    master_file.structure_title
  end

  def range
    structure_ng_xml.root.blank? ? simple_iiif_range : structure_to_iiif_range
  end

  # @return [IIIFManifest::V3::DisplayContent] the display content required by the manifest builder.
  def display_content
    return if master_file.derivative_ids.empty?
    master_file.is_video? ? video_content : audio_content
  end

  def annotation_content
    supplemental_captions_transcripts.uniq.collect { |file| supplementing_content_data(file) }.flatten
  end

  def sequence_rendering
    supplemental_files_rendering(master_file)
  end

  def see_also
    [
      {
        "@id" => "#{@master_file.waveform_master_file_url(@master_file.id)}.json",
        "type" => "Dataset",
        "label" => { "en" => ["waveform.json"] },
        "format" => "application/json"
      }
    ]
  end

  def placeholder_content
    if @master_file.derivative_ids.size > 0
      # height and width from /models/master_file/extract_still method
      IIIFManifest::V3::DisplayContent.new( @master_file.poster_master_file_url(@master_file.id),
                                            width: 1280,
                                            height: 720,
                                            type: 'Image',
                                            format: 'image/jpeg')
    elsif section_processing?(@master_file)
      IIIFManifest::V3::DisplayContent.new(nil,
                                           label: I18n.t('media_object.conversion_msg'),
                                           width: 1280,
                                           height: 720,
                                           type: 'Text',
                                           format: 'text/plain')
    else
      support_email = Settings.email.support
      IIIFManifest::V3::DisplayContent.new(nil,
                                           label: I18n.t('errors.missing_derivatives_error') % [support_email, support_email],
                                           width: 1280,
                                           height: 720,
                                           type: 'Text',
                                           format: 'text/plain')
    end
  end

  def service
    [
      {
        "@id" => "#{Rails.application.routes.url_helpers.search_master_file_url(master_file.id)}",
        "type" => "SearchService2"
      }
    ]
  end

  private

    def video_content
      # @see https://github.com/samvera-labs/iiif_manifest
      stream_urls.collect { |quality, url, mimetype| video_display_content(quality, url, mimetype) }
    end

    def video_display_content(quality, url, mimetype)
      if mimetype.present? && mimetype != 'application/x-mpegURL'
        IIIFManifest::V3::DisplayContent.new(url, **manifest_attributes(quality, 'Video', mimetype: mimetype))
      else
        IIIFManifest::V3::DisplayContent.new(Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file.id, quality: quality),
                                             **manifest_attributes(quality, 'Video'))
      end
    end

    def audio_content
      stream_urls.collect { |quality, url, mimetype| audio_display_content(quality, url, mimetype) }
    end

    def audio_display_content(quality, url, mimetype)
      if mimetype.present? && mimetype != 'application/x-mpegURL'
        IIIFManifest::V3::DisplayContent.new(url, **manifest_attributes(quality, 'Sound', mimetype: mimetype))
      else
        IIIFManifest::V3::DisplayContent.new(Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file.id, quality: quality),
                                             **manifest_attributes(quality, 'Sound'))
      end
    end

    def supplementing_content_data(file)
      unless file.is_a?(SupplementalFile)
        url = Rails.application.routes.url_helpers.captions_master_file_url(master_file.id)
        return IIIFManifest::V3::AnnotationContent.new(body_id: url, **supplemental_attributes(file))
      end

      tags = file.tags.reject { |t| t == 'machine_generated' }.compact
      case tags
      when ['caption']
        url = Rails.application.routes.url_helpers.captions_master_file_supplemental_file_url(master_file.id, file.id)
        IIIFManifest::V3::AnnotationContent.new(body_id: url, **supplemental_attributes(file, type: 'caption'))
      when ['transcript']
        url = Rails.application.routes.url_helpers.transcripts_master_file_supplemental_file_url(master_file.id, file.id)
        IIIFManifest::V3::AnnotationContent.new(body_id: url, **supplemental_attributes(file, type: 'transcript'))
      when ['caption', 'transcript']
        caption_url = Rails.application.routes.url_helpers.captions_master_file_supplemental_file_url(master_file.id, file.id)
        transcript_url = Rails.application.routes.url_helpers.transcripts_master_file_supplemental_file_url(master_file.id, file.id)
        [IIIFManifest::V3::AnnotationContent.new(body_id: caption_url, **supplemental_attributes(file, type: 'caption')),
         IIIFManifest::V3::AnnotationContent.new(body_id: transcript_url, **supplemental_attributes(file, type: 'transcript'))]
      else
        url = Rails.application.routes.url_helpers.master_file_supplemental_file_url(master_file.id, file.id)
        IIIFManifest::V3::AnnotationContent.new(body_id: url, **supplemental_attributes(file))
      end
    end

    def stream_urls
      stream_info[:stream_hls].collect do |d|
        [d[:quality], d[:url], d[:mimetype]]
      end
    end

    def section_processing?(master_file)
      !master_file.succeeded?
    end

    def supplemental_captions_transcripts
      files = master_file.supplemental_files(tag: 'caption') + master_file.supplemental_files(tag: 'transcript')
      files += [master_file.captions] if master_file.has_captions?
      files
    end

    def simple_iiif_range(label = stream_info[:label])
      IiifManifestRange.new(
        label: { "none" => [label] },
        items: [
          IiifCanvasPresenter.new(master_file: master_file, stream_info: stream_info, media_fragment: "t=0,#{stream_info[:duration]}")
        ]
      )
    end

    def structure_to_iiif_range
      root_to_iiif_range(structure_ng_xml.root)
    end

    def root_to_iiif_range(root_node)
      range = div_to_iiif_range(root_node)

      range.items.prepend(IiifCanvasPresenter.new(master_file: master_file, stream_info: stream_info, media_fragment: "t=0,#{stream_info[:duration]}"))

      return range
    end

    def div_to_iiif_range(div_node)
      items = div_node.children.select(&:element?).collect do |node|
        if node.name == "Div"
          div_to_iiif_range(node)
        elsif node.name == "Span"
          span_to_iiif_range(node)
        end
      end

      IiifManifestRange.new(
        label: { "none" => [div_node[:label]] },
        items: items
      )
    end

    def span_to_iiif_range(span_node)
      fragment = "t=#{parse_hour_min_sec(span_node[:begin])},#{parse_hour_min_sec(span_node[:end])}"
      IiifManifestRange.new(
        label: { "none" => [span_node[:label]] },
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

    def manifest_attributes(quality, media_type, mimetype: 'application/x-mpegURL')
      media_hash = {
        label: quality,
        width: (master_file.width || '1280').to_i,
        height: (master_file.height || MasterFile::AUDIO_HEIGHT).to_i,
        duration: stream_info[:duration],
        type: media_type,
        format: mimetype
      }.compact

      if master_file.media_object.visibility == 'public'
        media_hash
      else
        media_hash.merge!(auth_service: auth_service(quality))
      end
    end

    def supplemental_attributes(file, type: nil)
      if file.is_a?(SupplementalFile)
        label = file.tags.include?('machine_generated') ? file.label + ' (machine generated)' : file.label
        format = if file.file.content_type == 'text/srt' && type == 'caption'
                   'text/vtt'
                 else
                   file.file.content_type
                 end
        language = file.language || 'en'
        filename = file.file.filename.to_s
      else
        label = 'English'
        format = file.mime_type
        language = 'en'
        filename = file.original_name.to_s
      end
      {
        motivation: 'supplementing',
        label: { language => [label], 'none' => [filename] },
        type: 'Text',
        format: format,
        language: language
      }
    end

    # Note that the method returns empty Nokogiri Document instead of nil when structure_tesim doesn't exist or is empty.
    def structure_ng_xml
      # TODO: The XML parser should handle invalid XML files, for ex, if a non-leaf node has no valid "Div" or "Span" children,
      # in which case SyntaxError shall be prompted to the user during file upload.
      # This can be done by defining some XML schema to require that at least one Div/Span child node exists
      # under root or each Div node, otherwise Nokogiri::XML parser will report error, and raise exception here.
      @structure_ng_xml ||= if master_file.has_structuralMetadata?
                              Nokogiri::XML(master_file.structuralMetadata.content)
                            else
                              Nokogiri::XML(nil)
                            end
    end

    def auth_service(quality)
      {
        "context": "http://iiif.io/api/auth/1/context.json",
        "@id": Rails.application.routes.url_helpers.new_user_session_url(login_popup: 1),
        "@type": "AuthCookieService1",
        "confirmLabel": I18n.t('iiif.auth.confirmLabel'),
        "description": I18n.t('iiif.auth.description'),
        "failureDescription": I18n.t('iiif.auth.failureDescription'),
        "failureHeader": I18n.t('iiif.auth.failureHeader'),
        "header": I18n.t('iiif.auth.header'),
        "label": I18n.t('iiif.auth.label'),
        "profile": "http://iiif.io/api/auth/1/login",
        "service": [
          {
            "@id": Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file.id, quality: quality),
            "@type": "AuthProbeService1",
            "profile": "http://iiif.io/api/auth/1/probe"
          },
          {
            "@id": Rails.application.routes.url_helpers.iiif_auth_token_url(id: master_file.id),
            "@type": "AuthTokenService1",
            "profile": "http://iiif.io/api/auth/1/token"
          },
          {
            "@id": Rails.application.routes.url_helpers.destroy_user_session_url,
            "@type": "AuthLogoutService1",
            "label": I18n.t('iiif.auth.logoutLabel'),
            "profile": "http://iiif.io/api/auth/1/logout"
          }
        ]
      }
    end
end
