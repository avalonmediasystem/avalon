module IiifSupplementalFileBehavior
  private

  def supplemental_files_rendering(object)
    object.supplemental_files(tag: nil).collect do |sf|
      {
        "@id" => object_supplemental_file_url(object, sf),
        "type" => determine_rendering_type(sf.file.content_type),
        "label" => { "en" => [sf.label] },
        "format" => sf.file.content_type
      }
    end
  end

  def object_supplemental_file_url(object, supplemental_file)
    if object.is_a? MasterFile
      Rails.application.routes.url_helpers.master_file_supplemental_file_url(id: supplemental_file.id, master_file_id: object.id)
    else
      Rails.application.routes.url_helpers.media_object_supplemental_file_url(id: supplemental_file.id, media_object_id: object.id)
    end
  end

  def determine_rendering_type(mime)
    case mime
    when 'application/pdf', 'application/msword', 'application/vnd.oasis.opendocument.text', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/html', 'text/plain', 'text/vtt'
      'Text'
    when /image\/.+/
      'Image'
    when /audio\/.+/
      'Audio'
    when /video\/.+/
      'Video'
    else
      'Dataset'
    end
  end
end
