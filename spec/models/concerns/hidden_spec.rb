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

describe Avalon::AccessControls::Hidden do

  before do
    class Foo < ActiveFedora::Base
      include Hydra::AccessControls::Permissions
      include Avalon::AccessControls::Hidden
    end
  end

  subject { Foo.new }

  describe "hidden" do
    it "should default to discoverable" do
      subject.hidden?.should be false
      subject.to_solr["hidden_bsi"].should be false
    end

    it "should set hidden?" do
      subject.hidden = true
      subject.hidden?.should be true
      subject.to_solr["hidden_bsi"].should be_truthy
    end
  end
end
