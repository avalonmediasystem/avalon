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

describe Users::ProvidersController do
  describe "#login" do
    describe "as an authenticated user" do
      it "should flash error if provider is missing" do
      end
      it "should flash error if email missing" do
      end
      it "should flash error if username missing" do
      end
      it "should login new user with new provider and username, with email" do
      end
      it "should login existing user if provider and username exist and same email" do
      end
      it "should login existing user if provider and username exist and change email if email changed" do
      end
      it "currently 4-25-16 should have only have one provider that is cas" do
      end
    end
  end

end
