# An AvalonAnnotation that represents a 'marker', an annotated time-point on a masterfile
# @since 5.0.1
class AvalonMarker < AvalonAnnotation
  belongs_to :playlist_item, class_name: PlaylistItem

  validates :playlist_item, :master_file, presence: true

  def to_json
    { id: id, marker: { title: title, start_time: start_time } }
  end
end
