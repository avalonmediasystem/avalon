require 'spec_helper'

describe Derivative do
  describe "masterfile" do
    it "should set relationships on self and masterfile" do
      derivative = Derivative.new
      mf = MasterFile.new
      mf.save
      derivative.save
      derivative.relationships_by_name[:self]["derivative_of"].size.should == 0
      mf.relationships_by_name[:self]["derivatives"].size.should == 0
      derivative.masterfile = mf
      derivative.relationships_by_name[:self]["derivative_of"].size.should == 1
      derivative.relationships_by_name[:self]["derivative_of"].first.should eq "info:fedora/#{mf.pid}"
      mf.relationships_by_name[:self]["derivatives"].size.should == 1
      mf.relationships_by_name[:self]["derivatives"].first.should eq "info:fedora/#{derivative.pid}"
      derivative.relationships_are_dirty.should be true
      mf.relationships_are_dirty.should be true
    end
  end
end
