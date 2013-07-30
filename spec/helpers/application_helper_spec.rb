# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

describe ApplicationHelper do
  describe "#active_for_controller" do
    before(:each) do
      helper.stub(:params).and_return({controller: 'media_objects'})
    end
    it "should return 'active' for matching controller names" do
      helper.active_for_controller('media_objects').should == 'active'
    end
    it "should return '' for non-matching controller names" do
      helper.active_for_controller('master_files').should == ''
    end
    it "should handle name-spaced controllers" do
      helper.stub(:params).and_return({controller: 'admin/groups'})
      helper.active_for_controller('admin/groups').should == 'active'
      helper.active_for_controller('groups').should == ''
    end
  end
end
