# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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
       dropbox_files = context[:mediaobject].collection.dropbox.all
       context[:dropbox_files] = dropbox_files 
       context
    end

    def after_step context
       context
    end

    def execute context
       deleted_parts = update_master_files context
       context[:notice] = "Several clean up jobs have been sent out. Their statuses can be viewed by your sysadmin at #{ Avalon::Configuration.lookup('matterhorn.cleanup_log') }" unless deleted_parts.empty?
       
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
  def update_master_files(context)
    mediaobject = context[:mediaobject]
    files = context[:parts] || {}
    deleted_parts = []
    if not files.blank?
      files.each_pair do |pid,part|
        selected_part = MasterFile.find(pid)

        if selected_part
          if part[:remove]
            deleted_parts << selected_part
            selected_part.destroy
          else
            selected_part.label = part[:label] unless part[:label].nil?
            selected_part.permalink = part[:permalink] unless part[:permalink].nil?
            selected_part.poster_offset = part[:poster_offset] unless part[:poster_offset].nil?
            unless selected_part.save
              context[:error] ||= []
              context[:error] << "#{selected_part.pid}: #{selected_part.errors.to_a.first.gsub(/(\d+)/) { |m| m.to_i.to_hms }}"
            end
          end
        end
      end
    end
    return deleted_parts
  end

  end
