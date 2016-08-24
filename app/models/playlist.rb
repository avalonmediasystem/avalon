class Playlist < ActiveRecord::Base
  belongs_to :user
  validates :user, presence: true
  validates :title, presence: true
  validates :comment, length: { maximum: 255 }
  validates :visibility, presence: true
  validates :visibility, inclusion: { in: proc { [PUBLIC, PRIVATE] } }

  after_initialize :default_values

  has_many :items, -> { order('position ASC') }, class_name: PlaylistItem, dependent: :destroy
  has_many :clips, -> { order('playlist_items.position ASC') }, class_name: AvalonClip, through: :items
  accepts_nested_attributes_for :items, allow_destroy: true

  # visibility
  PUBLIC = 'public'
  PRIVATE = 'private'

  # Default values to be applied after initialization
  def default_values
    self.visibility ||= Playlist::PRIVATE
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

  class << self
    # Find the playlists that belong to this user/ability
    def for_ability(ability)
      accessible_by(ability, :update).order('playlists.created_at DESC')
    end

    # Find the i18n default playlist name
    def default_folder_name
      I18n.translate(:'playlists.default_playlist_name')
    end
  end # class << self
end
