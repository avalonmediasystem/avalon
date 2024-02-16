# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

namespace :avalon do
  namespace :migrate do
    desc "Set new collection managers property on collection model as part of bugfix allowing users that belong to the manager group to be given the editor role"
    task collection_managers: :environment do
      Admin::Collection.all.each do |collection|
        next unless collection.collection_managers.blank?
        # initialize to old behavior
        collection.collection_managers = collection.edit_users & ( Avalon::RoleControls.users("manager") | (Avalon::RoleControls.users("administrator") || []) )
        collection.save!(validate: false)
      end
    end
    desc "Migrate legacy IndexedFile captions to ActiveStorage as part of supporting upload of multiple captions files"
    task caption_files: :environment do
      count = 0
      MasterFile.all.each do |master_file|
        next unless master_file.captions.present?
        # Retrieve original file metadata from IndexedFile
        filename = master_file.captions.original_name
        content_type = master_file.captions.mime_type
        # Legacy captions were not stored as an attached file.
        # Write the plaintext content into a Tempfile to load into ActiveStorage.
        file = Tempfile.new(filename)
        file.write(master_file.captions.content)
        file.close
        # Create new SupplementalFile record
        supplemental_file = SupplementalFile.new(label: filename, tags: ['caption'], language: 'eng')
        # Attach file to SupplementalFile using original metadata
        supplemental_file.file.attach(io: File.open(file.path), filename: filename, content_type: content_type, identify: false)
        supplemental_file.save
        # Delete tempfile
        file.unlink
        # Link new SupplementalFile to the MasterFile
        master_file.supplemental_files += [supplemental_file]
        # Delete legacy caption file
        master_file.captions.content = ''
        master_file.captions.original_name = ''
        # Save record
        master_file.save

        count += 1
      end

      puts "Successfully updated #{count} records"
    end
  end
end
