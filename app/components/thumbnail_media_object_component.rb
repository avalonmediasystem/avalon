class ThumbnailMediaObjectComponent < Blacklight::Document::ThumbnailComponent
  # For some reason this method does not exist in this class even though it is present
  # in the superclass. We have to explicitly add it.
  def thumbnail_value
    @thumbnail_value ||= presenter.thumbnail.render(@image_options)
  end
end
