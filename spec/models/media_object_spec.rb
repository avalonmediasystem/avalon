require 'spec_helper'

describe MediaObject do
  let (:mediaobject) { MediaObject.new }

  describe "Required metadata is present" do
    it "should have no errors on creator if creator present" do
      mediaobject.update_attribute_in_metadata(:creator, 'John Doe')
      mediaobject.should have(0).errors_on(:creator)
    end
    it "should have no errors on title if title present" do
      mediaobject.update_attribute_in_metadata(:title, 'Title')
      mediaobject.should have(0).errors_on(:title)
    end
    it "should have no errors on date_created if date_created present" do
      mediaobject.update_attribute_in_metadata(:date_created, '2012-12-12')
      mediaobject.should have(0).errors_on :date_created
    end
    it "should have errors if requied fields are missing" do
      mediaobject.should have(1).errors_on(:creator)
      mediaobject.should have(1).errors_on(:title)
      mediaobject.should have(1).errors_on(:date_created)
    end
    it "should have errors if required fields are empty" do
      mediaobject.update_attribute_in_metadata :creator, ''
      mediaobject.update_attribute_in_metadata :title, ''
      mediaobject.update_attribute_in_metadata :date_created, ''

      mediaobject.should have(1).errors_on(:creator)
      mediaobject.should have(1).errors_on(:title)
      mediaobject.should have(1).errors_on(:date_created)
    end
  end

  describe "Field persistance" do
    it "should reject unknown fields"
    it "should update the contributors field" do
      load_fixture 'hydrant:electronic-resource'
      mediaobject = MediaObject.find 'hydrant:electronic-resource'
      mediaobject.update_attribute_in_metadata :contributor, 'Updated contributor'
      mediaobject.save

      mediaobject.contributor.length.should == 1
      mediaobject.contributor.should == ['Updated contributor']
    end

    it "should support multiple contributors" do
      load_fixture 'hydrant:print-publication'
      mediaobject = MediaObject.find 'hydrant:print-publication'
      mediaobject.contributor = ['Chris Colvard', 'Phuong Dinh', 'Michael Klein', 
        'Nathan Rogers']
      mediaobject.save
      mediaobject.contributor.length.should > 1
    end

    it "should support multiple publishers" do
      load_fixture 'hydrant:video-segment'
      mediaobject = MediaObject.find 'hydrant:video-segment'
      mediaobject.publisher.length.should == 1
      
      mediaobject.publisher = ['Indiana University', 'Northwestern University',
        'Ohio State University', 'Notre Dame']
      mediaobject.save
      mediaobject.publisher.length.should > 1
    end
  end
  
  describe "Valid formats" do
    it "should only accept ISO formatted dates"
  end
  
  describe "access" do
    it "should set access level to public" do
      mediaobject = MediaObject.new
      mediaobject.access = "public"
      mediaobject.read_groups.should =~ ["public", "registered"]
    end
    it "should set access level to restricted" do
      mediaobject = MediaObject.new
      mediaobject.access = "restricted"
      mediaobject.read_groups.should =~ ["registered"]
    end
    it "should set access level to private" do
      mediaobject = MediaObject.new
      mediaobject.access = "private"
      mediaobject.read_groups.should =~ []
    end
    it "should return public" do
      mediaobject = MediaObject.new
      mediaobject.read_groups = ["public", "registered"]
      mediaobject.access.should eq "public"
    end
    it "should return restricted" do
      mediaobject = MediaObject.new
      mediaobject.read_groups = ["registered"]
      mediaobject.access.should eq "restricted"
    end
    it "should return private" do
      mediaobject = MediaObject.new
      mediaobject.read_groups = []
      mediaobject.access.should eq "private"
    end
  end

  describe "Ingest status" do
    it "should default to unpublished" do
      mediaobject.workflow.published.first.should eq "false"
      mediaobject.workflow.published?.should eq false
    end

    it "should be published when the item is visible" do
      mediaobject.workflow.publish

      mediaobject.workflow.published.should == ['true'] 
      mediaobject.workflow.last_completed_step.first.should == HYDRANT_STEPS.last.step
    end

    it "should recognize the current step" do
      mediaobject.workflow.last_completed_step = 'structure'
      mediaobject.workflow.current?('access-control').should == true
    end

    it "should verify that the current step is last when the item is published" do
      mediaobject.workflow.publish
      mediaobject.workflow.last_completed_step.should == ['preview']
    end

    it "should default to the first workflow step" do
      mediaobject.workflow.last_completed_step.should == ['']
    end
  end

  describe 'change additional read permisions' do 
    it "should be able to add more groups" do
      mediaobject.access = "public"
      default_groups = mediaobject.read_groups

      test_groups = ["group1", "group2"]
      mediaobject.groups = test_groups

      # new read_groups should preserve default_groups and contain test_groups
      (default_groups - mediaobject.read_groups).should be_empty 
      (test_groups - mediaobject.read_groups).should be_empty           
    end

    it "should not add duplicated group" do
      mediaobject.access = "public"
      test_groups = ["group1", "group1", mediaobject.read_groups.first]
      mediaobject.groups = test_groups
      
      mediaobject.read_groups.should eql mediaobject.read_groups.uniq
    end
  end

  describe '#finished_processing?' do
    it 'returns true if the statuses indicate processing is finished' do
      mediaobject = MediaObject.new
      mediaobject.parts << MasterFile.new(status_code: ['STOPPED'])
      mediaobject.parts << MasterFile.new(status_code: ['SUCCEEDED'])
      mediaobject.finished_processing?.should be_true
    end
    it 'returns true if the statuses indicate processing is not finished' do
      mediaobject = MediaObject.new
      mediaobject.parts << MasterFile.new(status_code: ['STOPPED'])
      mediaobject.parts << MasterFile.new(status_code: ['RUNNING'])
      mediaobject.finished_processing?.should be_false
    end
  end
end
