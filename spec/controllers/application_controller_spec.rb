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

require 'spec_helper'

describe ApplicationController do
  controller do
    def create
      render nothing: true
    end
  end

  context "normal auth" do
    it "should check for authenticity token" do
      expect(controller).to receive(:verify_authenticity_token)
      post :create
    end
  end
  context "ingest API" do
    it "should not check for authenticity token for API requests" do
      request.headers['Avalon-Api-Key'] = 'secret_token'
      expect(controller).not_to receive(:verify_authenticity_token)
      post :create
    end
  end
end
