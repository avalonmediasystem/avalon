module ApplicationHelper
  def application_name
    'Hydrant'
  end
  
  def image_for(item_id)
    #TODO index the thumbnail url to avoid having to hit fedora to get it
    media_object = MediaObject.find(item_id)
    masterfile = media_object.parts.first 

    imageurl = thumbnail_master_file_path(masterfile) unless masterfile.nil? or masterfile.thumbnail.new?
    imageurl ||= case
                 when media_object.format == "Moving image"
                   "video_icon.png"
                 when media_object.format == "Sound"
                   "audio_icon.png"
                 when (media_object.parts.length >= 2) 
                   # TODO
                   # We need to test if both audio and video are present
                   # instead of assuming when there is more than one part
                   "hybrid_icon.png" 
                 else
                   nil
                 end
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

  #FIXME
  #This helper should be used by blacklight to display the "Title" field in search results
  def search_result_label item
    label = item.id
    unless item["title_display"].blank?
      label = truncate(item["title_display"], length: 35)
    end
    
    if ! item['duration_t'].nil? && ! item['duration_t'].empty? 
      item_duration = item['duration_t'].first
      if item_duration.respond_to?(:to_i)
        formatted_duration = milliseconds_to_formatted_time(item_duration.to_i)
        label += "(#{formatted_duration})"
      end
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
        label = File.basename(resource.file_location)
      else
        label = resource.label
      end
    end
    label
  end

  #Taken from Hydra::Controller::ControllerBehavior
  def user_key
    current_user.user_key if current_user
  end

  # the mediainfo gem returns duration as milliseconds
  # see attr_reader.rb line 48 in the mediainfo source
  def milliseconds_to_formatted_time( milliseconds, format = :short )
    if milliseconds >= 1000
      seconds = milliseconds / 1000
      ChronicDuration.output(seconds, :format => format)
    else
      'less than 1 second'
    end
  end

end
