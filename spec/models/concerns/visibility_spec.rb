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

describe Hydra::AccessControls::Visibility do

  before do
    class Foo < ActiveFedora::Base
      include Hydra::AccessControls::Permissions
      include Hydra::AccessControls::Visibility
    end
  end

  subject { Foo.new }

  describe "#visibility=" do
    it "should raise error on invalid visibility value" do
      expect {subject.visibility="blahalklkadsjfl"}.to raise_error(ArgumentError)
    end
  end

  describe "#visibility" do
    it "should return public visibility if public group is present" do
      subject.read_groups = [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    it "should return authenticated visibility if authenticated group is present" do
subject.read_groups = [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
      expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED

    end
    it "should default to private visibility" do
      expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
   
    end
  end
end
