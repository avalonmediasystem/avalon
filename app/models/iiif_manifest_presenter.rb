# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

class IiifManifestPresenter
  attr_reader :media_object, :master_files

  def initialize(media_object:, master_files:)
    @media_object = media_object
    @master_files = master_files
  end

  def file_set_presenters
    # Only return master files that have derivatives to avoid oddities in the manifest and failures in iiif_manifest
    master_files.select { |mf| mf.derivative_ids.size > 0 }
  end

  def work_presenters
    []
  end

  def manifest_url
    Rails.application.routes.url_helpers.manifest_media_object_url(media_object)
  end

  def description
    media_object.abstract
  end

  def to_s
    media_object.title
  end

  def manifest_metadata
    @manifest_metadata ||= iiif_metadata_fields.collect do |f|
      value = media_object.send(f)
      next if value.blank?
      { 'label' => f.to_s.titleize, 'value' => Array(value) }
    end.compact
  end

  def thumbnail
    @thumbnail ||= image_for(media_object.to_solr)
  end

  def ranges
    [
      IiifManifestRange.new(
        label: { '@none'.to_sym => media_object.title },
        items: file_set_presenters.collect(&:range)
      )
    ]
  end

  def homepage
    [
      {
        id: Rails.application.routes.url_helpers.media_object_url(media_object),
        type: "Text",
        label: { "none" => [I18n.t('iiif.manifest.homepageLabel')] },
        format: "text/html"
      }
    ]
  end

  private

    def iiif_metadata_fields
      # TODO: refine and order this list of fields
      [:title, :creator, :date_created, :date_issued, :note, :contributor,
       :publisher, :subject, :genre, :geographic_subject, :temporal_subject, :topical_subject, :rights_statement]
    end

    def image_for(document)
      master_file_id = document["section_id_ssim"].try :first

      video_count = document["avalon_resource_type_ssim"].count{|m| m.start_with?('moving image'.titleize) } rescue 0
      audio_count = document["avalon_resource_type_ssim"].count{|m| m.start_with?('sound recording'.titleize) } rescue 0

      if master_file_id
        if video_count > 0
         Rails.application.routes.url_helpers.thumbnail_master_file_url(master_file_id)
        elsif audio_count > 0
          ActionController::Base.helpers.asset_url('audio_icon.png')
        else
          nil
        end
      else
        if video_count > 0 && audio_count > 0
          ActionController::Base.helpers.asset_url('hybrid_icon.png')
        elsif video_count > audio_count
          ActionController::Base.helpers.asset_url('video_icon.png')
        elsif audio_count > video_count
          ActionController::Base.helpers.asset_url('audio_icon.png')
        else
          nil
        end
      end
    end
end
