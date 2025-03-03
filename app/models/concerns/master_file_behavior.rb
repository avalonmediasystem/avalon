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

require 'htmlentities'

module MasterFileBehavior
  QUALITY_ORDER = { "auto" => 1, "high" => 2, "medium" => 3, "low" => 4 }.freeze
  EMBED_SIZE = { medium: 600 }.freeze
  AUDIO_HEIGHT = 40

  def status?(value)
    status_code == value
  end

  def failed?
    status?('FAILED')
  end

  def succeeded?
    status?('COMPLETED')
  end

  def stream_details
    flash, hls = [], []

    common, caption_paths = nil, nil

    derivatives.each do |d|
      common = { quality: d.quality,
                 bitrate: d.bitrate,
                 mimetype: d.mime_type,
                 format: d.format }
      flash << common.merge(url: d.streaming_url(false))

      hls_url = d.streaming_url(true)
      # Quick fix for old items with mimetypes to deal with issue due to mp3 progressive download code in IIIFCanvasPresenter
      common[:mimetype] = 'application/x-mpegURL' if File.extname(hls_url) == ".m3u8"

      hls << common.merge(url: d.streaming_url(true))
    end
    if hls.length > 1
      hls << { quality: 'auto',
               mimetype: hls.first[:mimetype],
               format: hls.first[:format],
               url: hls_manifest_master_file_url(id: id, quality: 'auto') }
    end

    # Sorts the streams in order of quality, note: Hash order only works in Ruby 1.9 or later
    flash = sort_streams flash
    hls = sort_streams hls

    poster_path = Rails.application.routes.url_helpers.poster_master_file_path(self)
    if has_captions?
      caption_paths = []
      supplemental_file_captions.each { |c| caption_paths.append(build_caption_hash(c)) }

      caption_paths.append(build_caption_hash(captions)) if captions.present?

      caption_paths
    end

    # Returns the hash
    return({
      id: self.id,
      label: structure_title,
      is_video: is_video?,
      poster_image: poster_path,
      embed_code: embed_code(EMBED_SIZE[:medium], {urlappend: '/embed'}),
      stream_flash: flash,
      stream_hls: hls,
      cookie_auth: cookie_auth?,
      caption_paths: caption_paths,
      duration: (duration.to_f / 1000),
      embed_title: embed_title
    })
  end

  # Copied and extracted from stream_details for use in the waveformjob
  # This isn't used in stream_details because it would be less efficient
  def hls_streams
    hls = []
    derivatives.each do |d|
      common = { quality: d.quality,
                 bitrate: d.bitrate,
                 mimetype: d.mime_type,
                 format: d.format }

      hls_url = d.streaming_url(true)
      # Quick fix for old items with mimetypes to deal with issue due to mp3 progressive download code in IIIFCanvasPresenter
      common[:mimetype] = 'application/x-mpegURL' if File.extname(hls_url) == ".m3u8"

      hls << common.merge(url: d.streaming_url(true))
    end
    if hls.length > 1
      hls << { quality: 'auto',
               mimetype: hls.first[:mimetype],
               format: hls.first[:format],
               url: hls_manifest_master_file_url(id: id, quality: 'auto') }
    end

    # Sorts the streams in order of quality
    sort_streams hls
  end

  def display_title
    mf_title = if has_structuralMetadata?
                 structuralMetadata.section_title
               elsif title.present?
                 title
               elsif file_location.present? && (media_object.section_ids.size > 1)
                 file_location.split("/").last
               end
    mf_title.blank? ? nil : mf_title
  end

  def embed_title
    [media_object.title, display_title].compact.join(" - ")
  end

  def structure_title
    display_title.present? ? display_title : media_object.title
  end

  def embed_code(width, permalink_opts = {})
    begin
      url = if self.permalink.present?
        self.permalink_with_query(permalink_opts)
      else
        embed_master_file_url(self.id)
      end
      height = is_video? ? (width/display_aspect_ratio.to_f).floor : AUDIO_HEIGHT
      "<iframe title=\"#{HTMLEntities.new.encode(embed_title)}\" src=\"#{url}\" width=\"#{width}\" height=\"#{height}\" frameborder=\"0\" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>"
    rescue
      ""
    end
  end

  def is_video?
    self.file_format != "Sound"
  end

  def cookie_auth?
    Settings.streaming.server == "aws"
  end

  def sort_streams array
    array.sort { |x, y| QUALITY_ORDER[x[:quality]] <=> QUALITY_ORDER[y[:quality]] }
  end

  def build_caption_hash(caption)
    if caption.is_a?(SupplementalFile)
      path = Rails.application.routes.url_helpers.master_file_supplemental_file_path(master_file_id: self.id, id: caption.id)
      language = caption.language
      label = caption.label
    else
      path = Rails.application.routes.url_helpers.captions_master_file_path(self)
      language = "en"
      label = nil
    end
    {
      path: path,
      mime_type: caption.mime_type,
      language: language,
      label: label
    }
  end

  def supplemental_file_captions
    supplemental_files(tag: 'caption')
  end

  def supplemental_file_transcripts
    supplemental_files(tag: 'transcript')
  end

  # Supplies the route to the master_file as an rdf formatted URI
  # @return [String] the route as a uri
  # @example uri for a mf on avalon.iu.edu with a id of: avalon:1820
  #   "my_master_file.rdf_uri" #=> "https://www.avalon.iu.edu/master_files/avalon:1820"
  def rdf_uri
    master_file_url(id)
  end

  # Returns the dctype of the master_file
  # @return [String] either 'dctypes:MovingImage' or 'dctypes:Sound'
  def rdf_type
    is_video? ? 'dctypes:MovingImage' : 'dctypes:Sound'
  end
end
