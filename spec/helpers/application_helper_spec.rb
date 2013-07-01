require 'spec_helper'

describe ApplicationHelper do
  describe "#active_for_controller" do
    before(:each) do
      helper.stub!(:params).and_return({controller: 'media_objects'})
    end
    it "should return 'active' for matching controller names" do
      helper.active_for_controller('media_objects').should == 'active'
    end
    it "should return '' for non-matching controller names" do
      helper.active_for_controller('master_files').should == ''
    end
    it "should handle name-spaced controllers" do
      helper.stub!(:params).and_return({controller: 'admin/groups'})
      helper.active_for_controller('admin/groups').should == 'active'
      helper.active_for_controller('groups').should == ''
    end
  end
end
