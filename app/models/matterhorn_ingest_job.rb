# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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

class MatterhornIngestJob < Struct.new(:args)
  def perform
    Rubyhorn.client.addMediaPackageWithUrl(args)
  end

  def error(job, exception)
    master_file = MasterFile.find(job.payload_object.args[:title])
    # add message here to update master file
    master_file.status_code = 'FAILED'
    master_file.error = exception.message
    master_file.save
  end

end
