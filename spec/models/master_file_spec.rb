require 'spec_helper'

describe MasterFile do
#  describe "container" do
#    it "should set relationships on self and container" do
#      mf = MasterFile.new
#      mo = MediaObject.new
#      mo.save(validate: false)
#      mf.relationships_by_name[:self]["part_of"].size.should == 0
#      mo.relationships_by_name[:self]["parts"].size.should == 0
#      mf.mediaobject = mo
#      mf.relationships_by_name[:self]["part_of"].size.should == 1
#      mf.relationships_by_name[:self]["part_of"].first.should eq "info:fedora/#{mo.pid}"
#      mo.relationships_by_name[:self]["parts"].size.should == 1
#      mo.relationships_by_name[:self]["parts"].first.should eq "info:fedora/#{mf.pid}"
#      mf.relationships_are_dirty.should be true
#      mo.relationships_are_dirty.should be true
#    end
#  end

  describe "masterfiles=" do
    it "should set hasDerivation relationships on self" do
      derivative = Derivative.new
      mf = MasterFile.new
      mf.save
      derivative.save

      mf.relationships(:is_derivation_of).size.should == 0

      mf.derivatives += [derivative]

      puts "#{mf.pid}: #{mf.relationships.to_a.to_s}"
      puts "#{derivative.pid}: #{derivative.relationships.to_a.to_s}"

      derivative.relationships(:is_derivation_of).size.should == 1
      derivative.relationships(:is_derivation_of).first.should == mf.internal_uri

      #derivative.relationships_are_dirty.should be true
    end
  end
end
