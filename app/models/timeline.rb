# frozen_string_literal: true

# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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

class Timeline < ActiveRecord::Base
  belongs_to :user
  scope :by_user, ->(user) { where(user_id: user.id) }
  scope :title_like, ->(title_filter) { where("title LIKE ?", "%#{title_filter}%") }
  scope :with_tag, ->(tag_filter) { where("tags LIKE ?", "%\n- #{tag_filter}\n%") }

  validates :user, presence: true
  validates :title, presence: true
  validates :description, length: { maximum: 255 }
  validates :visibility, presence: true
  validates :visibility, inclusion: { in: proc { [PUBLIC, PRIVATE, PRIVATE_WITH_TOKEN] } }

  delegate :url_helpers, to: 'Rails.application.routes'

  after_initialize :default_values
  before_save :generate_access_token, if: proc { |p| p.visibility == Timeline::PRIVATE_WITH_TOKEN && access_token.blank? }
  after_create :generate_manifest
  serialize :tags

  # visibility
  PUBLIC = 'public'
  PRIVATE = 'private'
  PRIVATE_WITH_TOKEN = 'private-with-token'

  # Default values to be applied after initialization
  def default_values
    self.visibility ||= Timeline::PRIVATE
    self.tags ||= []
  end

  def generate_manifest
    self.manifest ||= manifest_builder.to_json
    save!
  end

  def generate_access_token
    # TODO: Use ActiveRecord's secure_token when we move to Rails 5
    self.access_token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless self.class.exists?(access_token: random_token)
    end
  end

  def valid_token?(token)
    access_token == token && visibility == Timeline::PRIVATE_WITH_TOKEN
  end

  private

    def manifest_url
      @manifest_url ||= Rails.application.routes.url_helpers.manifest_timeline_url(self)
    end

    def duration
      begin_time, end_time = source.split("?t=")[1].split(",")
      end_time ||= master_file.duration.to_f / 1000
      end_time.to_f - begin_time.to_f
    end

    def master_file
      master_file = ActiveFedora::Base.where(identifier_ssim: master_file_id.downcase).first
      master_file ||= ActiveFedora::Base.find(master_file_id, cast: true) rescue nil
    end

    def master_file_id
      source.split("?")[0].split('/').last
    end

    def source_stream
      media_fragment = source.split("?t=")[1]
      Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file_id, quality: 'auto', anchor: "t=#{media_fragment}")
    end

    def manifest_builder
      {
        "@context": [
          "http://digirati.com/ns/timeliner",
          "http://www.w3.org/ns/anno.jsonld",
          "http://iiif.io/api/presentation/3/context.json"
        ],
        "id": manifest_url,
        "type": "Manifest",
        "label": {
          "en": [
            title
          ]
        },
        "items": [
          {
            "id": "#{manifest_url}/canvas",
            "type": "Canvas",
            "duration": duration,
            "items": [
              {
                "id": "#{manifest_url}/annotations",
                "type": "AnnotationPage",
                "items": [
                  {
                    "id": "#{manifest_url}/annotations/1",
                    "type": "Annotation",
                    "motivation": "painting",
                    "body": {
                      "id": source_stream,
                      "type": "Audio",
                      "duration": duration
                    },
                    "target": "#{manifest_url}/canvas"
                  }
                ]
              }
            ]
          }
        ]
      }
    end
end
