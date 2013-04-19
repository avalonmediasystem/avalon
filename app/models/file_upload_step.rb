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

require 'avalon/dropbox'

  class FileUploadStep < Avalon::Workflow::BasicStep
    def initialize(step = 'file-upload', 
                   title = "Manage file(s)", 
                   summary = "Associated bitstreams",
                   template = 'file_upload')
      super
    end

    # For file uploads the process of setting the context is easy. We
    # just need to ask the dropbox if there are any files. If so load
    # them into a variable that can be referred to later
    def before_step context
       dropbox_files = Avalon::DropboxService.all
       context[:dropbox_files] = dropbox_files 
       context
    end

    def after_step context
       context
    end

    def execute context
         logger.debug "<< Processing FILE-UPLOAD step >>"
       deleted_parts = update_master_files context[:mediaobject], context[:parts] 
       context[:notice] = "Several clean up jobs have been sent out. Their statuses can be viewed by your sysadmin at #{ Avalon::Configuration['matterhorn']['cleanup_log'] }" unless deleted_parts.empty?
       
       # Reloads mediaobject.parts, should use .reload when we update hydra-head 
       media = MediaObject.find(context[:mediaobject].pid)
       unless media.parts.empty?
         media.save(validate: false)
         context[:mediaobject] = media
       end

       context
    end

  # Passing in an ordered array of values update the master files below a
  # MediaObject. Accepted hash keys are
  #
  # remove - Set to true to delete this item
  # label - Display label in the interface
  # pid - Identifier for the masterFile to help with mapping
  def update_master_files(mediaobject, files = [])
    deleted_parts = []
    if not files.blank?
      files.each do |part|
        logger.debug "<< #{part} >>"
        selected_part = mediaobject.parts.find{|p| p.pid == part[:pid]}

        if selected_part
          if part[:remove]
            logger.info "<< Deleting master file #{selected_part.pid} from the system >>"
            deleted_parts << selected_part
            selected_part.destroy
          else
            selected_part.label = part[:label]
            selected_part.save
          end
        end
      end
    end
    return deleted_parts
  end

  end
