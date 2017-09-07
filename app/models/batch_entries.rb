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

#Handles the registration of individual ingests for batch
#@since 6.3.0

require 'acts_as_list'

class BatchEntries < ActiveRecord::Base
  belongs_to :batch_registries
  acts_as_list scope: :batch_registries
  before_save :mininum_viable_metadata

  # Determines if we have the mininum viable metadata needed to ingest an object
  # Sets an error on the row when we do not
  def mininum_viable_metadata
    fields = JSON.parse(payload)['fields']
    return nil unless fields['date_issued'].nil? || fields['title'].nil?
    return nil unless fields['bibliographic_id'].nil?
    self.error = true
    self.error_message = 'To successfully ingest, either title and date issued must be set or a bibliographic id must be provided'
  end
end
