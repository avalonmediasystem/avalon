class Playlist < ActiveRecord::Base
  belongs_to :user
  validates :user, presence: true
  validates :title, presence: true
  validates :comment, length: { maximum: 255 }
  validates :visibility, presence: true
  validates :visibility, inclusion: { in: proc { [PUBLIC, PRIVATE] } }

  after_initialize :default_values

  has_many :items, -> { order('position ASC') }, class_name: PlaylistItem, dependent: :destroy
  has_many :annotations, -> { order('playlist_items.position ASC') }, class_name: AvalonAnnotation, through: :items
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
    uri = AvalonAnnotation.where(id: current_item.annotation_id)[0].source
    items = PlaylistItem.joins(:annotation).where('annotations.source_uri' => uri).where(playlist: self)
    # remove the current item
    return_items = []
    items.each do |item|
      return_items << item unless item.annotation_id == current_item.annotation_id
    end
    return_items
  end

  # Returns all other annotations on the same playlist that share a master file
  # @param [PlaylistItem] current_item The playlist item you want to find matches for
  # @return [Array <AvalonAnnotation>] an array of all other annotations items that reference the same master file
  def related_annotations(current_item)
    annotations = []
    related_items(current_item).each do |item|
      annotations << AvalonAnnotation.find(item.annotation_id)
    end
    annotations
  end

  # Returns a list of annotations who are on the same playlist, share the same masterfile, and whose start time falls within the start and end time of the current playlist item
  # @param [PlaylistItem] current_item The playlist item to match against
  # @return [Array <AvalonAnnotation>] all annotations matching the constraints
  def related_annotations_time_contrained(current_item)
    current_anno = AvalonAnnotation.where(id: current_item.annotation_id)[0]
    annos = []
    related_items(current_item).each do |item|
      anno = AvalonAnnotation.where(id: item.annotation_id)[0]
      annos << anno if anno.start_time <= current_anno.end_time && anno.start_time >= current_anno.start_time
    end
    annos
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
