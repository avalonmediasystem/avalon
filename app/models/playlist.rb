class Playlist < ActiveRecord::Base
  belongs_to :user
  validates :user, presence: true
  validates :title, presence: true
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
