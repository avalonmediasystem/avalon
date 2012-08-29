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
    it "should have errors if requied fields are missing" do
      mo = MediaObject.new
      mo.should have(1).errors_on(:creator)
      mo.should have(1).errors_on(:title)
      mo.should have(1).errors_on(:created_on)
    end
    it "should have errors if required fields are empty" do
      mo = MediaObject.new(creator: "", title: "", created_on: "")
      mo.should have(1).errors_on(:creator)
      mo.should have(1).errors_on(:title)
      mo.should have(1).errors_on(:created_on)
    end
  end

  describe "Field persistance" do
    it "should reject unknown fields"
    it "should update the contributors field"
      mo = FactoryGirl.create(:single_entry)
      mo.contributor = 'Updated contributor'
      mo.save

      mo = MediaObject.find(mo.pid)
      mo.contributor.length.should == 1
      mo.contributor.should == ['Updated contributor']
    it "should support multiple contributors"
      mo = FactoryGirl.create(:multiple_entries)
      mo.contributor.length.should > 1
    it "should support multiple publishers"
      mo = FactoryGirl.create(:single_entry)
      mo.publisher.length.should == 1
      new_value = [mo.publisher.first, 'Secondary publisher']
      mo.publisher = new_value
      
      puts "<< #{mo.publisher} >>"
      mo.publisher.length.should > 1
  end
  
  describe "Valid formats" do
    it "should only accept ISO formatted dates"
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
