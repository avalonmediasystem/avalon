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

require 'rails_helper'

describe ReindexJob do
  let(:job) { ReindexJob.new }
  describe "perform" do
    let(:objs) { [ActiveFedora::Base.create!, ActiveFedora::Base.create!] }
    it 'calls reindex on each id passed' do
      objs.each {|obj| allow(ActiveFedora::Base).to receive(:find).with(obj.id, cast: true).and_return(obj)}
      objs.each {|obj| expect(obj).to receive(:update_index)}
      job.perform(objs.map(&:id))
    end
  end
end
