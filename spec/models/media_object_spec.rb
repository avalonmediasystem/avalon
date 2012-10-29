require 'spec_helper'

describe MediaObject do
  describe "Required metadata is present" do
    it "should have no errors on creator if creator present" do
      mo = MediaObject.new
      mo.update_attribute(:creator, 'John Doe')
      mo.should have(0).errors_on(:creator)
    end
    it "should have no errors on title if title present" do
      mo = MediaObject.new
      mo.update_attribute(:main_title, 'Title')
      mo.should have(0).errors_on(:title)
    end
    it "should have no errors on date_created if date_created present" do
      mo = MediaObject.new
      mo.update_attribute(:date_created, '2012-12-12')
      mo.should have(0).errors_on :date_created
    end
    it "should have errors if requied fields are missing" do
      mo = MediaObject.new
      mo.should have(1).errors_on(:creator)
      mo.should have(1).errors_on(:title)
      mo.should have(1).errors_on(:date_created)
    end
    it "should have errors if required fields are empty" do
      mo = MediaObject.new
      mo.update_attribute :creator, ''
      mo.update_attribute :main_title, ''
      mo.update_attribute :date_created, ''

      mo.should have(1).errors_on(:creator)
      mo.should have(1).errors_on(:title)
      mo.should have(1).errors_on(:date_created)
    end
  end

  describe "Field persistance" do
    it "should reject unknown fields"
    it "should update the contributors field" do
      pending "Test is horribly broken and needs to be fixed" 
      
      #mo = FactoryGirl.create(:single_entry)
      #mo.contributor = 'Updated contributor'
      #mo.save

      #mo = MediaObject.find(mo.pid)
      #mo.contributor.length.should == 1
      #mo.contributor.should == ['Updated contributor']
    end
    it "should support multiple contributors" do
      pending "Test is broken and needs to be fixed"
      
      #mo = FactoryGirl.create(:multiple_entries)
      #mo.contributor.length.should > 1
    end
    it "should support multiple publishers" do
      pending "Test is broken and needs to be fixed"
      #mo = FactoryGirl.create(:single_entry)
      
      #mo.publisher.length.should == 1
      #new_value = [mo.publisher.first, 'Secondary publisher']
      #mo.publisher = new_value
      #mo.publisher.length.should > 1
    end
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
