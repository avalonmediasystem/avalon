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
    audio_types = ["audio/vnd.wave", "audio/mpeg", "audio/mp4"]
    video_types = ["video/mpeg2", "video/mp4"]
    wrong_format = false
    if params.has_key?(:Filedata) and params.has_key?(:original)
      @video_assets = []
  		params[:Filedata].each do |file|
  		  if !video_types.include?(file.content_type) && !audio_types.include?(file.content_type)
  	      wrong_format = true
  	      break
  		  end
  		  
  			@video_assets << video_asset = saveOriginalToHydrant(file)
  			sendOriginalToMatterhorn(video_asset, file)
  			#TODO store Workflow instance id and/or MediaPackage in VideoDCDatastream so we can show processing status on edit page later
  		end
    else
      flash[:notice] = "You must specify a file to upload."
    end
    
    respond_to do |format|
      if !params[:container_id].nil? && !wrong_format
      	format.html { redirect_to :controller => "catalog", :action => "edit", :id => params[:container_id] }
      	format.js
      else 
        format.html { redirect_to :controller => "catalog", :action => "index"}
        format.js 
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

  def sendOriginalToMatterhorn(video_asset, file)
    args = {"title" => video_asset.pid , "flavor" => "presenter/source", "workflow" => "hydrant", "filename" => video_asset.label}
    mp = Rubyhorn.client.addMediaPackage(file, args)
    flash[:notice] = "The uploaded file has been sent to Matterhorn for processing."
  end

	def update
   if params.has_key?(:video_url)
      notice = process_files
      flash[:notice] = notice.join("<br/>".html_safe) unless notice.blank?
		end
	end

  def process_files
    logger.debug "In process_files of video_assets_controller"
    video_asset = VideoAsset.find(params[:id]) 
		video_asset.url = params[:video_url]

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
end
