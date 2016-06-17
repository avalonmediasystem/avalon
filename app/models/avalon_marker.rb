# An AvalonAnnotation that represents a 'marker', an annotated time-point on a masterfile
# @since 5.0.1
class AvalonMarker < AvalonAnnotation
  belongs_to :PlaylistItem
end
