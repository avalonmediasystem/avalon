module MediaObjectsHelper
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
      
      # Quick and dirty solution to the problem of displaying the right template.
      # Quick and dirty also gets it done faster.
      def current_step_for(status=nil)
        if status.nil?
          status = HYDRANT_STEPS.first
        end
        
        # Fun fact - Q&D also stands for 'Quick and Deadly' or 'Quiche and Dandelions'
        HYDRANT_STEPS.template(status)
      end
end


