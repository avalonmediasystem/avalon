# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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

class BatchRegistries < ActiveRecord::Base
  # Register a new batch ingest file into the database
  # @param Avalon::Batch::Package the package to register
  # @return BatchRegistries the ActiveRecord entry of the package
  def new(package)
    self.email = package.user.email
    self.file_name = package.title
    self.replay_name = "#{SecureRandom.uuid}-#{package.title}"
    self.collection = package.collection.id
    self.valid_manifest = true
    self.completed = false
    self.email_sent = false
    self.locked = true
    self.save
  end

  def load_manifest(package)
  end


end
