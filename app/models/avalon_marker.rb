# An extension of the ActiveAnnotations gem to include Avalon specific information in the Annotation
# Sets defaults for the annotation using information from the master_file and includes solrization of the annotation
# @since 5.0.0
class AvalonMarker < AvalonMediafragment
  belongs_to :PlaylistItem
end
