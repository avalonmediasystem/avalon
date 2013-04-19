# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

class DropboxController < ApplicationController
  before_filter :authenticate_user!

  def bulk_delete
    unless can? :manage, Dropbox
      raise CanCan::AccessDenied
    end

    # failsafe for spaces that might be attached to string
    filenames = params[:filenames].map(&:strip)

    dropbox_filenames = Avalon::DropboxService.all.map{|f| f[:name] }
    deleted_filenames = []

    filenames.each do |filename|
      if dropbox_filenames.include?( filename )
        if Avalon::DropboxService.delete( filename ) 
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
