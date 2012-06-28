module VideosHelper
	  # Creates a hot link to the downloadable file if it is available. File names longer
	  # than 25 characters are truncated although this can be overridden by passing in a
	  # different value
	  def file_download_label(video_asset)
		# Check to see if the file name is longer than 25 characters
		if 25 > video_asset.descMetadata.title[0].length 
		  label_display = video_asset.descMetadata.title[0]
		else
		  label_display = truncate(video_asset.descMetadata.title[0], length: 20)
                  label_display << "."
		  label_display << video_asset.descMetadata.title[0].split('.').last
		end
	  end
end


