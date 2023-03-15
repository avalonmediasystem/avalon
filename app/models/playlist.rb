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

class Playlist < ActiveRecord::Base
  belongs_to :user
  scope :by_user, ->(user) { where(user_id: user.id) }
  scope :title_like, ->(title_filter) { where("title LIKE ?", "%#{title_filter}%")}
  scope :with_tag, ->(tag_filter) { where("tags LIKE ?", "%\n- #{tag_filter}\n%") }

  validates :user, presence: true
  validates :title, presence: true
  validates :comment, length: { maximum: 255 }
  validates :visibility, presence: true
  validates :visibility, inclusion: { in: proc { [PUBLIC, PRIVATE, PRIVATE_WITH_TOKEN] } }

  delegate :url_helpers, to: 'Rails.application.routes'

  after_initialize :default_values
  before_save :generate_access_token, if: Proc.new{ |p| p.visibility == Playlist::PRIVATE_WITH_TOKEN && access_token.blank? }

  has_many :items, -> { order('position ASC') }, class_name: 'PlaylistItem', dependent: :destroy
  has_many :clips, -> { order('playlist_items.position ASC') }, class_name: 'AvalonClip', through: :items
  accepts_nested_attributes_for :items, allow_destroy: true

  serialize :tags

  # visibility
  PUBLIC = 'public'
  PRIVATE = 'private'
  PRIVATE_WITH_TOKEN = 'private-with-token'

  # Default values to be applied after initialization
  def default_values
    self.visibility ||= Playlist::PRIVATE
    self.tags ||= [];
  end

  def generate_access_token
    # TODO Use ActiveRecord's secure_token when we move to Rails 5
    self.access_token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless self.class.exists?(access_token: random_token)
    end
  end

  # Returns all other playlist items on the same playlist that share a master file
  # @param [PlaylistItem] current_item The playlist item you want to find matches for
  # @return [Array <PlaylistItem>] an array of all other playlist items that reference the same master file
  def related_items(current_item)
    uri = AvalonClip.where(id: current_item.clip_id)[0].source
    items = PlaylistItem.joins(:clip).where('annotations.source_uri' => uri).where(playlist: self)
    # remove the current item
    return_items = []
    items.each do |item|
      return_items << item unless item.clip_id == current_item.clip_id
    end
    return_items
  end

  # Returns all other clips on the same playlist that share a master file
  # @param [PlaylistItem] current_item The playlist item you want to find matches for
  # @return [Array <AvalonClip>] an array of all other clips items that reference the same master file
  def related_clips(current_item)
    clips = []
    related_items(current_item).each do |item|
      clips << AvalonClip.find(item.clip_id)
    end
    clips
  end

  # Returns a list of clips that are on the same playlist, share the same masterfile, and whose start time falls within the start and end time of the current playlist item
  # @param [PlaylistItem] current_item The playlist item to match against
  # @return [Array <AvalonClip>] all clips matching the constraints
  def related_clips_time_contrained(current_item)
    current_clip = AvalonClip.where(id: current_item.clip_id)[0]
    clips = []
    related_items(current_item).each do |item|
      clip = AvalonClip.where(id: item.clip_id)[0]
      clips << clip if clip.start_time <= current_clip.end_time && clip.start_time >= current_clip.start_time
    end
    clips
  end

  def valid_token?(token)
    access_token == token && visibility == Playlist::PRIVATE_WITH_TOKEN
  end

  class << self
    # Find the i18n default playlist name
    def default_folder_name
      I18n.translate(:'playlists.default_playlist_name')
    end
  end # class << self
end
