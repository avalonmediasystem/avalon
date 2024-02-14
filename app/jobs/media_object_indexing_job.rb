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

class MediaObjectIndexingJob < ApplicationJob
  queue_as :media_object_indexing

  # Only enqueue one indexing job at a time but once one starts running allow others to be enqueued
  # because the first step of the job is fetching the object from fedora at which point it might
  # be stale and subsequent jobs might get a newer version of the media object.
  unique :until_executing, on_conflict: :log

  def perform(id)
    mo = MediaObject.find(id)
    ActiveFedora::SolrService.add(mo.to_solr(include_child_fields: true), softCommit: true)
  end
end
