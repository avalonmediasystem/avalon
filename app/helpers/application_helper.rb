module ApplicationHelper
    def application_name
      'Hydrant'
    end
    
    def image_for_result(item)
      # Overwrite this to return the preview from Matterhorn. Be sure to include the
      # image_tag call so it renders properly
      media_object = MediaObject.find(item[:id])
      
      # TODO : I have an idea how to refactor this to make it more neat but it needs to
      #        wait until the email form is finished.
      if media_object.format == "Moving image"
        imageurl = "video_icon.jpg"
      elsif media_object.format == "Sound"
        imageurl = "audio_icon.png"
      elsif (media_object.parts.length >= 2)
        imageurl = "hybrid_icon.png"
      else
        imageurl = "no_icon.png"
      end

      # Retrieve the icon from Matterhorn if it is present and replace it with an
      # actual thumbnail
      unless (media_object.parts.blank?)
        master_file = MasterFile.find(media_object.parts.first.pid)
        workflow_doc = Rubyhorn.client.instance_xml master_file.descMetadata.source.first
        imageurl = workflow_doc.searchpreview.first unless (workflow_doc.searchpreview.nil? or workflow_doc.searchpreview.empty?)
      end
      # Audio files do not currently have an icon so provide the default
      
      image_tag imageurl
    end
end
