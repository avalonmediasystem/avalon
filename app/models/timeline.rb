# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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
  # Explicitly cast everything to lowercase for DB agnostic case-insentive search.
  scope :title_like, ->(title_filter) { where("LOWER(title) LIKE ?", "%#{title_filter.downcase}%") }
  scope :desc_like, ->(desc_filter) { where("LOWER(description) LIKE ?", "%#{desc_filter.downcase}%") }
  scope :with_tag, ->(tag_filter) { where("LOWER(tags) LIKE ?", "%\n- #{tag_filter.downcase}\n%") }

  validates :user, presence: true
  validates :title, presence: true
  validates :description, length: { maximum: 512 }
  validates :visibility, presence: true
  validates :visibility, inclusion: { in: proc { [PUBLIC, PRIVATE, PRIVATE_WITH_TOKEN] } }

  delegate :url_helpers, to: 'Rails.application.routes'

  after_initialize :default_values
  before_validation :synchronize_title
  before_validation :synchronize_description
  before_validation :standardize_source
  before_validation :standardize_homepage
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

  def standardize_source
    return unless source.present? && source_changed?
    media_fragment = source.split("?t=")[1]
    self.source = Rails.application.routes.url_helpers.master_file_url(master_file) + "?t=#{media_fragment}"
  end

  def standardize_homepage
    return unless manifest.present? && source.present? && (source_changed? || manifest_changed?)
    media_fragment = source.split("?t=")[1]
    base_url = master_file.permalink if master_file.permalink.present?
    base_url ||= Rails.application.routes.url_helpers.master_file_url(master_file)

    manifest_json = JSON.parse(manifest)
    manifest_json["homepage"] ||= []
    manifest_json["homepage"][0] ||= {}
    manifest_json["homepage"][0]["id"] = "#{base_url}?t=#{media_fragment}"
    self.manifest = manifest_json.to_json
  end

  def generate_manifest
    return unless source.present?
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

  def synchronize_title
    return if manifest.blank?

    manifest_json = JSON.parse(manifest)
    manifest_json["label"] ||= {}
    manifest_json["label"]["en"] ||= []

    if title_changed?
      manifest_json["label"]["en"] = [title]
      self.manifest = manifest_json.to_json
    end
    if manifest_changed?
      self.title = manifest_json["label"]["en"].first
    end
  end

  def synchronize_description
    return if manifest.blank?

    manifest_json = JSON.parse(manifest)
    manifest_json["summary"] ||= {}
    manifest_json["summary"]["en"] ||= []

    if description_changed?
      manifest_json["summary"]["en"] = [description]
      self.manifest = manifest_json.to_json
    end
    if manifest_changed?
      self.description = manifest_json["summary"]["en"].first
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
      # must avoid floating point arithmatic errors
      ((end_time.to_f * 1000).to_i - (begin_time.to_f * 1000).to_i) / 1000.0
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
        "summary": {
          "en": [
            description
          ]
        },
        "homepage": [
          {
            "id": source,
            "type": "Text",
            "label": {
              "en": [
                "View Source Item"
              ]
            },
            "format": "text/html"
          }
        ],
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
                      "type": master_file.is_video? ? "Video" : "Audio",
                      "duration": duration,
                      "service": [auth_service]
                    },
                    "target": "#{manifest_url}/canvas"
                  }
                ]
              }
            ]
          }
        ],
        "structures": []
      }
    end

    def auth_service
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
            "@id": Rails.application.routes.url_helpers.iiif_auth_token_url(id: master_file_id),
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
