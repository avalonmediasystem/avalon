module ApplicationHelper
    def application_name
      'Hydrant'
    end
    
    def image_for_result(item)
      # Overwrite this to return the preview from Matterhorn. Be sure to include the
      # image_tag call so it renders properly
      image_tag "reel-to-reel.jpg"
    end
end
