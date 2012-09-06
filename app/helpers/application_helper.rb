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
        imageurl = "reel-to-reel.jpg"
      elsif media_object.format == "Sound"
        imageurl = "audio-icon.png"
      else
        imageurl = "Question_mark.png"
      end

      unless (media_object.parts.nil? or media_object.parts.empty?)
        master_file = MasterFile.find(media_object.parts.first.pid)
        workflow_doc = Rubyhorn.client.instance_xml master_file.descMetadata.source.first
        imageurl = workflow_doc.searchpreview.first unless (workflow_doc.searchpreview.nil? or workflow_doc.searchpreview.empty?)
      end
      # Audio files do not currently have an icon so provide the default
      
      image_tag imageurl
    end
end
