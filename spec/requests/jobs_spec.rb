# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

require 'rails_helper.rb'

describe 'Jobs WebUI', type: :request do
  describe 'routing' do
    context 'as an administrator' do
      before do
        allow_any_instance_of(Avalon::Routing::CanConstraint).to receive(:matches?).and_return(true)
      end
      it "can access /jobs" do
        get jobs_path
        expect(response).to have_http_status(200)
      end
    end

    context 'as an end-user' do
      before do
        allow_any_instance_of(Avalon::Routing::CanConstraint).to receive(:matches?).and_return(false)
      end
      it "redirects to root when unauthorized request to /jobs" do
        get jobs_path
        expect(response).to have_http_status(301)
      end
    end
  end
end
