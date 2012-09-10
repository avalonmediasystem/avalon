require 'net/http/digest_auth'

class DerivativesController < ApplicationController

 #  before_filter :enforce_access_controls
 # load_and_authorize_resource
  
  skip_before_filter :verify_authenticity_token, :only => [:create]
#  before_filter :authenticate_user!, :only => [:create]

  # Creates and Saves a File Asset to contain the the Uploaded file 
  # If container_id is provided:
  # * the File Asset will use RELS-EXT to assert that it's a part of the specified container
  # * the method will redirect to the container object's edit view after saving
  def create
    # if cannot? :create, Derivative
    #   flash[:notice] = "You do not have sufficient privileges to add derivative files"
    #   redirect_to root_path 
    #   return
    # end

   masterfile = MasterFile.find(params[:master])
#   if cannot? :edit, masterfile.container.pid
#     flash[:notice] = "You do not have sufficient privileges to add derivative files"
#     redirect_to root_path
#     return
#   end

      derivative = Derivative.new
      derivative.source = masterfile.source
      derivative.url = params[:stream_url]
      derivative.save
      derivative.masterfile = masterfile
      masterfile.save
      derivative.save		
  end

end
