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
    if params.has_key?(:number_of_files) and params[:number_of_files] != "0"
      return redirect_to({:controller => "catalog", :action => "edit", :id => params[:id], :wf_step => :files, :number_of_files => params[:number_of_files]})
    elsif params.has_key?(:number_of_files) and params[:number_of_files] == "0"
      return redirect_to( {:controller => "catalog", :action => "edit", :id => params[:id]} )
    end
    
    if params.has_key?(:Filedata) and params.has_key?(:original)
	sendOriginalToMatterhorn
	#TODO store Workflow instance id and/or MediaPackage in VideoDCDatastream so we can show processing status on edit page later
	flash[:notice] = "The uploaded file has been sent to Matterhorn for processing."
    elsif params.has_key?(:video_url)
      notice = process_files
      flash[:notice] = notice.join("<br/>".html_safe) unless notice.blank?
    else
      flash[:notice] = "You must specify a file to upload."
    end
    
    unless params[:container_id].nil?
      redirect_params = {:controller => "catalog", :action => "edit", :id => params[:container_id]}
    end
    redirect_params ||= {:controller => "catalog", :action => "index"}
    
    redirect_to redirect_params
  end
  
  def sendOriginalToMatterhorn
	params[:Filedata].each do |file|
          args = {"title" => params[:container_id], "flavor" => "presenter/source", "workflow" => "hydrant", "filename" => file.original_filename}
	  Rubyhorn.client.addMediaPackage(file, args)
	end
   end

  def process_files
    logger.debug "In process_files of video_assets_controller"
    video_asset = create_and_save_video_asset_from_params
    notice = []
      apply_depositor_metadata(video_asset)

      notice << render_to_string(:partial=>'file_assets/asset_saved_flash', :locals => { :file_asset => video_asset })
        
      if !params[:container_id].nil?
        associate_file_asset_with_container(video_asset,'info:fedora/' + params[:container_id])
      end

      ## Apply any posted file metadata
      unless params[:asset].nil?
        logger.debug("applying submitted file metadata: #{@sanitized_params.inspect}")
        apply_file_metadata
      end
      # If redirect_params has not been set, use {:action=>:index}
      logger.debug "Created #{video_asset.pid}."
    notice
  end

  # Creates a Video Asset, adding the posted blob to the Video Asset's datastreams and saves the Video Asset
  #
  # @return [VideoAsset] the Video Asset  
  def create_and_save_video_asset_from_params
    if params.has_key?(:video_url)
        video_asset = create_asset_from_video_url(params[:video_url])
        video_asset.save
      return video_asset
    else
      render :text => "400 Bad Request", :status => 400
    end
  end
  
  def create_asset_from_video_url(url)
    video_asset = VideoAsset.new
    filename = url.split(/\//).last
    video_asset.label = filename

#    ds = ActiveFedora::Datastream.new(:dsid=> "content", :label => filename, :controlGroup => "E", :dsLocation => url, :mimeType=>mime_type(filename))
#    video_asset.add_datastream(ds)
#    ds = video_asset.create_datastream(ActiveFedora::Datastream, "content", :dsid=> "content", :dsLabel => filename, :controlGroup => "R", :dsLocation => url, :mimeType=>mime_type(filename))
#    video_asset.add_datastream(ds)

#    video_asset.add_named_datastream("content", :dsid=>"content", :label=>filename, :dsLocation=>url, :mimeType=>mime_type(filename))
    video_asset.set_url(url)
    video_asset.set_title_and_label( filename, :only_if_blank=>true )

    return video_asset
  end

end
