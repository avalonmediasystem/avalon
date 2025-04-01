# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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
                 title = "Manage files",
                 summary = "Associated bitstreams",
                 template = 'file_upload')
    super
  end

  # For file uploads the process of setting the context is easy. We
  # just need to ask the dropbox if there are any files. If so load
  # them into a variable that can be referred to later
  def before_step context
    dropbox_files = context[:media_object].collection.dropbox.all
    context[:dropbox_files] = dropbox_files
    context
  end

  def after_step context
    context
  end

  def execute context
    deleted_sections = update_master_files context
    context[:notice] = "Several clean up jobs have been sent out. Their statuses can be viewed by your sysadmin at #{ Settings.matterhorn.cleanup_log }" unless deleted_sections.empty?

    media = MediaObject.find(context[:media_object].id)
    context[:media_object] = media

    context
  end

  # Passing in an ordered array of values update the master files below a
  # MediaObject. Accepted hash keys are
  #
  # remove - Set to true to delete this item
  # label - Display label in the interface
  # id - Identifier for the masterFile to help with mapping
  def update_master_files(context)
    files = context[:master_files] || {}
    deleted_sections = []
    if not files.blank?
      files.each_pair do |id,master_file|
        selected_master_file = MasterFile.find(id)

        if selected_master_file
          if master_file[:remove]
            deleted_sections << selected_master_file
            selected_master_file.destroy
          else
            selected_master_file.title = master_file[:title] unless master_file[:title].nil?
            selected_master_file.permalink = master_file[:permalink] unless master_file[:permalink].nil?
            selected_master_file.poster_offset = master_file[:poster_offset] unless master_file[:poster_offset].nil?
            selected_master_file.date_digitized = master_file[:date_digitized].blank? ? nil : master_file[:date_digitized] unless master_file[:date_digitized].nil?
            unless selected_master_file.save
              context[:error] ||= []
              context[:error] << "#{selected_master_file.id}: #{selected_master_file.errors.to_a.first.gsub(/(\d+)/) { |m| m.to_i.to_hms }}"
            end
          end
        end
      end
    end
    deleted_sections
  end
end
