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
      load_fixture 'hydrant:electronic-resource'
      mo = MediaObject.find 'hydrant:electronic-resource'
      mo.update_attribute :contributor, 'Updated contributor'
      mo.save

      mo.contributor.length.should == 1
      mo.contributor.should == ['Updated contributor']
    end

    it "should support multiple contributors" do
      load_fixture 'hydrant:print-publication'
      mo = MediaObject.find 'hydrant:print-publication'
      mo.contributor = ['Chris Colvard', 'Phuong Dinh', 'Michael Klein', 
        'Nathan Rogers']
      mo.save
      mo.contributor.length.should > 1
    end

    it "should support multiple publishers" do
      load_fixture 'hydrant:video-segment'
      mo = MediaObject.find 'hydrant:video-segment'
      mo.publisher.length.should == 1
      
      mo.publisher = ['Indiana University', 'Northwestern University',
        'Ohio State University', 'Notre Dame']
      mo.save
      mo.publisher.length.should > 1
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

  describe "Ingest status" do
    it "should default to unpublished" do
      @mediaobject = MediaObject.new
      @mediaobject.workflow.published.first.should eq "false"
      @mediaobject.workflow.published?.should eq false
    end

    it "should be published when the item is visible" do
      mediaobject = MediaObject.new
      mediaobject.workflow.publish

      mediaobject.workflow.published.should == ['true'] 
      mediaobject.workflow.last_completed_step.first.should == HYDRANT_STEPS.last.step
    end

    it "should recognize the current step" do
      mediaObject = MediaObject.new
      mediaObject.workflow.last_completed_step = 'structure'
      mediaObject.workflow.current?('access-control').should == true
    end

    it "should verify that the current step is last when the item is published" do
      mediaObject = MediaObject.new
      mediaObject.workflow.publish
      mediaObject.workflow.last_completed_step.should == ['preview']
    end

    it "should default to the first workflow step" do
      mediaObject = MediaObject.new
      mediaObject.workflow.last_completed_step.should == ['']
    end
  end
end
