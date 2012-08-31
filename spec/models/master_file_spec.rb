require 'spec_helper'

describe MasterFile do
  describe "container" do
    it "should set relationships on self and container" do
      mf = MasterFile.new
      mo = MediaObject.new
      mo.save(validate: false)
      mf.save
      mf.relationships_by_name[:self]["part_of"].size.should == 0
      mo.relationships_by_name[:self]["parts"].size.should == 0
      mf.container = mo
      mf.relationships_by_name[:self]["part_of"].size.should == 1
      mf.relationships_by_name[:self]["part_of"].first.should eq "info:fedora/#{mo.pid}"
      mo.relationships_by_name[:self]["parts"].size.should == 1
      mo.relationships_by_name[:self]["parts"].first.should eq "info:fedora/#{mf.pid}"
      mf.relationships_are_dirty.should be true
      mo.relationships_are_dirty.should be true
    end
  end
end
