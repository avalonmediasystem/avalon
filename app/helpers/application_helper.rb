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
        imageurl = "video_icon.png"
      elsif media_object.format == "Sound"
        imageurl = "audio_icon.png"
      elsif (media_object.parts.length >= 2)
        imageurl = "hybrid_icon.png"
      else
        puts "FORMAT: #{media_object.format}"
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

    # Creates a hot link to the downloadable file if it is available. File names longer
    # than 25 characters are truncated although this can be overridden by passing in a
    # different value
    def file_download_label(masterfile)
    # Check to see if the file name is longer than 25 characters
    if 20 > masterfile.descMetadata.title[0].length 
      label_display = masterfile.descMetadata.title[0]
    else
      label_display = truncate(masterfile.descMetadata.title[0], length: 15)
                  label_display << "."
      label_display << masterfile.descMetadata.title[0].split('.').last
    end
    end
    
    # Not the best way to do this but it works for the time being
    def wrap_text(content)
      unless content.nil? or content.empty?
        content.gsub(/\n/, '<br />').html_safe
      else
        "<em>Not provided</em>".html_safe
      end
    end

    def display_multiple(value, delim='; ')
      value.select { |v| not (v.nil? or v.strip.empty?) }.join(delim)
    end

    def search_result_label(item)
       label = ''
       unless item["title_t"].nil? or item["title_t"].empty?
         label << truncate(item["title_t"].first, length: 35)
       else
         label << item.id
       end
       
       label
    end

    # Retrieve the current status of processing and display a concise version
    # for use in the interface
    def conversion_status_for(mediaobject)
      unless mediaobject.parts.empty?
        masterfile = mediaobject.parts.first.pid
        masterfile.status
      else
        "No files have been selected"
      end
    end   
    
    def stream_label_for(resource)
      label = ''
      unless resource.nil?
        if resource.label.blank?
          label = File.basename(resource.descMetadata.identifier[0])
        else
          label = resource.label
        end
      end
      return label
    end

  #Taken from Hydra::Controller::ControllerBehavior
  def user_key
    current_user.user_key if current_user
  end

end
