require 'spec_helper'

describe MediaObject do
  describe "presence_of_required_metadata" do
    it "should have no errors on creator if creator present" do
      MediaObject.new(creator: "John Doe").should have(0).errors_on(:creator)
    end
    it "should have no errors on title if title present" do
      MediaObject.new(title: "Title").should have(0).errors_on(:title)
    end
    it "should have no errors on created_on if created_on present" do
      MediaObject.new(created_on: "2012-01-01").should have(0).errors_on(:created_on)
    end
    it "should have errors if fields not present" do
      MediaObject.new().should have(1).errors_on(:creator)
      MediaObject.new().should have(1).errors_on(:title)
      MediaObject.new().should have(1).errors_on(:created_on)
    end
    it "should have errors if fields empty" do
      MediaObject.new(creator: "").should have(1).errors_on(:creator)
      MediaObject.new(title: "").should have(1).errors_on(:title)
      MediaObject.new(created_on: "").should have(1).errors_on(:created_on)
    end
  end

  describe "access" do
    it "should set access level to public" do
      @mediaobject = MediaObject.new
      @mediaobject.access = "public"
      @mediaobject.read_groups.should =~ ["public", "registered"]
    end
    it "should set access level to restricted" do
      @mediaobject = MediaObject.new
      @mediaobject.access = "restricted"
      @mediaobject.read_groups.should =~ ["registered"]
    end
    it "should set access level to private" do
      @mediaobject = MediaObject.new
      @mediaobject.access = "private"
      @mediaobject.read_groups.should =~ []
    end
    it "should return public" do
      @mediaobject = MediaObject.new
      @mediaobject.read_groups = ["public", "registered"]
      @mediaobject.access.should eq "public"
    end
    it "should return restricted" do
      @mediaobject = MediaObject.new
      @mediaobject.read_groups = ["registered"]
      @mediaobject.access.should eq "restricted"
    end
    it "should return private" do
      @mediaobject = MediaObject.new
      @mediaobject.read_groups = []
      @mediaobject.access.should eq "private"
    end
  end
end
