class DropboxController < ApplicationController
  before_filter :authenticate_user!

  def bulk_delete
    unless can? :manage, Dropbox
      raise CanCan::AccessDenied
    end

    # failsafe for spaces that might be attached to string
    filenames = params[:filenames].map(&:strip)

    dropbox_filenames = Hydrant::DropboxService.all.map{|f| f[:name] }
    deleted_filenames = []

    filenames.each do |filename|
      if dropbox_filenames.include?( filename )
        if Hydrant::DropboxService.delete( filename ) 
          deleted_filenames << filename
          logger.info "The user #{current_user.username} deleted #{filename} from the dropbox."
        end
      else
        logger.warn "The user #{current_user.username} attempted to delete #{filename} from the dropbox. File does not exist."
      end
    end
    
    render :json => { deleted_filenames: deleted_filenames }
  end
  
end