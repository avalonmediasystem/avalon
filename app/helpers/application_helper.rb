module ApplicationHelper
    def application_name
      'Hydrant'
    end
    
    def image_for_result(item)
      # Overwrite this to return the preview from Matterhorn. Be sure to include the
      # image_tag call so it renders properly
      video = Video.find(item[:id])
      if video.descMetadata.format.first == "Moving image"
        imageurl = "reel-to-reel.jpg"
      elsif video.descMetadata.format.first == "Sound"
        imageurl = "audio-icon.png"
      else
        imageurl = "Question_mark.png"
      end

      unless (video.parts.nil? or video.parts.empty?)
        video_asset = VideoAsset.find(video.parts.first.pid)
        workflow_doc = Rubyhorn.client.instance_xml video_asset.descMetadata.source.first
        imageurl = workflow_doc.searchpreview.first unless (workflow_doc.searchpreview.nil? or workflow_doc.searchpreview.empty?)
      end
      # Audio files do not currently have an icon so provide the default
      
      image_tag imageurl
    end
end
