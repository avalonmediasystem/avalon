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

class IngestBatchEntryJob < ActiveJob::Base
  queue_as :ingest

  # ActiveJob will serialize/deserialize the batch_entry automatically using GlobalIDs
  def perform(batch_entry)
    # TODO validation checking that it is okay to ingest this batch entry
    # TODO delete pre-existing media object
    entry = Avalon::Batch::Entry.new(nil, nil, batch_entry.payload, nil, nil)
    if entry.valid?
      entry.process!
    else
      # TODO Report error
    end
    # TODO any post processing to update status?
  end
end
