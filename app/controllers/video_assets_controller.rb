require 'net/http/digest_auth'
require 'net/http/post/multipart'
require 'rubyhorn'

class VideoAssetsController < ApplicationController
  include Hydra::FileAssets
  
  skip_before_filter :verify_authenticity_token, :only => [:create]

  # Creates and Saves a File Asset to contain the the Uploaded file 
  # If container_id is provided:
  # * the File Asset will use RELS-EXT to assert that it's a part of the specified container
  # * the method will redirect to the container object's edit view after saving
  def create
    audio_types = ["audio/vnd.wave", "audio/mpeg", "audio/mp3", "audio/mp4", "audio/wav"]
    video_types = ["application/mp4", "video/mpeg", "video/mpeg2", "video/mp4", "video/quicktime"]
    unknown_types = ["application/octet-stream", "application/x-upload-data"]
    
    wrong_format = false    
    @upload_format = 'unknown'
    
    if params.has_key?(:Filedata) and params.has_key?(:original)
      @video_assets = []
      params[:Filedata].each do |file|
        puts "<< MIME type is #{file.content_type} >>"
  	@upload_format = 'video' if video_types.include?(file.content_type)
  	@upload_format = 'audio' if audio_types.include?(file.content_type)
  		  
  	# If the content type cannot be inferred from the MIME type fall back on the
  	# list of unknown types. This is different than a generic fallback because it
  	# is skipped for known invalid extensions like application/pdf
  	@upload_format = determine_format_by_extension(file) if unknown_types.include?(file.content_type)
  	puts "<< Uploaded file appears to be #{@upload_format} >>"
  		  
  	if 'unknown' == @upload_format
  	  wrong_format = true
  	  break
  	end
  		  
  			@video_assets << video_asset = saveOriginalToHydrant(file)
  			if video_asset.save
    			video_asset = sendOriginalToMatterhorn(video_asset, file)
                        video = Video.find(video_asset.container.pid)
                        
                        puts "<< #{video.pid} >>"
                        video.descMetadata.format = case @upload_format
                          when 'audio'
                            'Sound'
                          when 'video'
                            'Moving image'
                          else
                            'Unknown'
                        end
                        puts "<< #{video.descMetadata.format} >>"
                        
                        video.save
   			video_asset.save
			  end
  		end
    else
      flash[:notice] = "You must specify a file to upload"
    end
    
    respond_to do |format|
      flash[:upload] = create_upload_notice(@upload_format)
      
      unless params[:container_id].nil?
      	format.html { 
          redirect_to edit_video_path(params[:container_id], step: 'file-upload') }
      	format.js { }
      else 
        format.html { 
	  redirect_to edit_video_path(params[:container_id], step: 'file-upload') }
        format.js { }
      end
    end
  end
  
  
	def saveOriginalToHydrant file
		public_dir_path = "public/"
		new_dir_path = public_dir_path + 'videos/' + params[:container_id].gsub(":", "_") + "/"
		new_file_path = new_dir_path + file.original_filename
		FileUtils.mkdir_p new_dir_path unless File.exists?(new_dir_path)
		FileUtils.rm new_file_path if File.exists?(new_file_path)
		FileUtils.cp file.tempfile, new_file_path

		video_asset = create_video_asset_from_temp_path(new_file_path[public_dir_path.length - 1, new_file_path.length - 1])		

 		notice = []
    apply_depositor_metadata(video_asset)

    #notice << render_to_string(:partial=>'file_assets/asset_saved_flash', :locals => { :file_asset => video_asset })
    @container_id = params[:container_id]
    if !@container_id.nil?
      associate_file_asset_with_container(video_asset,'info:fedora/' + @container_id)

      ## Apply any posted file metadata
      unless params[:asset].nil?
        logger.debug("applying submitted file metadata: #{@sanitized_params.inspect}")
        apply_file_metadata
      end

      # If redirect_params has not been set, use {:action=>:index}
      logger.debug "Created #{video_asset.pid}."
    	notice	
		end
  	video_asset
	end

  def sendOriginalToMatterhorn(video_asset, file, upload_format)
    args = {"title" => video_asset.pid , "flavor" => "presenter/source", "filename" => video_asset.label}
    if upload_format == 'audio'
      args['workflow'] = "fullaudio"
    elsif upload_format == 'video'
      args['workflow'] = "hydrant"
    end
    puts "<< Callling Matterhorn with arguments: #{args} >>"
    workflow_doc = Rubyhorn.client.addMediaPackage(file, args)
    flash[:notice] = "The uploaded file has been sent for processing."
    video_asset.description = "File is being processed"
    
    # I don't know why this has to be double escaped with two arrays
    video_asset.source = workflow_doc.workflow.id[0]
    video_asset
  end

	def update
   if params.has_key?(:video_url)
      notice = process_files
      flash[:notice] = notice.join("<br/>".html_safe) unless notice.blank?
	render :nothing => true
		end
	end

  def process_files
    logger.debug "In process_files of video_assets_controller"
    video_asset = VideoAsset.find(params[:id]) 
		video_asset.url = params[:video_url]
		video_asset.description = "File processed and ready for streaming"
		
		if video_asset.save
			notice = []
			notice << render_to_string(:partial=>'hydra/file_assets/asset_saved_flash', :locals => { :file_asset => video_asset })
        
      # If redirect_params has not been set, use {:action=>:index}
      logger.debug "Updated #{video_asset.pid} with URL #{params[:video_url]}."
    	notice
		else 
			notice = "File updating failed"
		end
  end

	def create_video_asset_from_temp_path(path)
		video_asset = VideoAsset.new
    filename = path.split(/\//).last
		video_asset.label = filename
		video_asset.url = path
		video_asset.description = "Original file uploaded"
		
		return video_asset		
	end
	
  # When destroying a file asset be sure to stop it first
  def destroy
    video_asset = VideoAsset.find(params[:id])
    parent = video_asset.container
    
    puts "<< Stopping #{video_asset.source[0]} >>"
    Rubyhorn.client.stop(video_asset.source[0])
    
    video_asset.delete
    redirect_to edit_video_path(parent.pid, step: "file-upload")
  end
  
  protected
  def determine_format_by_extension(file) 
    audio_extensions = ["mp3", "wav", "aac", "flac"]
    video_extensions = ["mpeg4", "mp4", "avi", "mov"]

    puts "<< Using fallback method to guess the format >>"

    extension = file.original_filename.split(".").last.downcase
    puts "<< File extension is #{extension} >>"
    
    # Default to unknown
    format = 'unknown'
    format = 'video' if video_extensions.include?(extension)
    format = 'audio' if audio_extensions.include?(extension)

    return format
  end
  
  def create_upload_notice(format) 
    case format
	   when /^audio$/
	     text = 'The uploaded content appears to be audio';
	   when /^video$/ 
	     text = 'The uploaded content appears to be video';
	   else
	     text = 'The uploaded content could not be identified';
	end 
	return text
  end
end
