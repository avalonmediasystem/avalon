# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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

module MasterFileBehavior
  QUALITY_ORDER = { "high" => 1, "medium" => 2, "low" => 3 }
  EMBED_SIZE = {:medium => 600}
  AUDIO_HEIGHT = 50

  def status?(value)
    status_code == value
  end

  def failed?
    status?('FAILED')
  end

  def succeeded?
    status?('COMPLETED')
  end

  def stream_details(token,host=nil)
    flash, hls = [], []

    common, poster_path, captions_path, captions_format = nil, nil, nil, nil, nil, nil

    derivatives.each do |d|
      common = { quality: d.quality,
                 mimetype: d.mime_type,
                 format: d.format }
      flash << common.merge(url: Avalon::Configuration.rehost(d.tokenized_url(token, false),host))
      hls << common.merge(url: Avalon::Configuration.rehost(d.tokenized_url(token, true),host))
    end

    # Sorts the streams in order of quality, note: Hash order only works in Ruby 1.9 or later
    flash = sort_streams flash
    hls = sort_streams hls

    poster_path = Rails.application.routes.url_helpers.poster_master_file_path(self) if has_poster?
    if has_captions?
      captions_path = Rails.application.routes.url_helpers.captions_master_file_path(self)
      captions_format = self.captions.mime_type
    end
    # Returns the hash
    return({
      id: self.id,
      label: title,
      is_video: is_video?,
      poster_image: poster_path,
      embed_code: embed_code(EMBED_SIZE[:medium], {urlappend: '/embed'}),
      stream_flash: flash,
      stream_hls: hls,
      captions_path: captions_path,
      captions_format: captions_format,
      duration: (duration.to_f / 1000),
      embed_title: embed_title
    })
  end

  def display_title
    mf_title = self.structuralMetadata.section_title unless self.structuralMetadata.blank?
    mf_title ||= self.title if self.title.present?
    mf_title ||= self.file_location.split( "/" ).last if self.file_location.present?
    mf_title.blank? ? nil : mf_title
  end

  def embed_title
    [ self.media_object.title, display_title ].compact.join(" - ")
  end

  def embed_code(width, permalink_opts = {})
    begin
      url = if self.permalink.present?
        self.permalink_with_query(permalink_opts)
      else
        embed_master_file_url(self.id, only_path: false, protocol: '//')
      end
      height = is_video? ? (width/display_aspect_ratio.to_f).floor : AUDIO_HEIGHT
      "<iframe title=\"#{ embed_title }\" src=\"#{url}\" width=\"#{width}\" height=\"#{height}\" frameborder=\"0\" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>"
    rescue
      ""
    end
  end

  def is_video?
    self.file_format != "Sound"
  end

  def sort_streams array
    array.sort { |x, y| QUALITY_ORDER[x[:quality]] <=> QUALITY_ORDER[y[:quality]] }
  end
end
