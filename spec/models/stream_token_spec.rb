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

describe StreamToken do
  let(:target) { '232A9B17-CCA8-4368-9599-117D2AF1D2EC' }

  describe "existing session" do
    let(:session) { { :session_id => '00112233445566778899aabbccddeeff' } }

    it "should create a token" do
      StreamToken.find_or_create_session_token(session, target).should =~ /^[0-9a-f]{40}$/
    end
  end

  describe "new session" do
    let(:session) { {} }

    it "should create a token" do
      StreamToken.find_or_create_session_token(session, target).should =~ /^[0-9a-f]{40}$/
    end
  end

  describe "delete session" do
    let(:session) { { :session_id => '00112233445566778899aabbccddeeff' } }
    describe "tokens exist" do
      let!(:token) {  StreamToken.find_or_create_session_token(session, target) }
      it "should delete existing tokens" do
        StreamToken.logout! session
        expect( StreamToken.exists? token ).to be_falsey
      end
    end
    describe "tokens don't exist" do
      it "should not bomb" do
        expect { StreamToken.logout! session }.not_to change { StreamToken.count }
      end
    end
  end

end
