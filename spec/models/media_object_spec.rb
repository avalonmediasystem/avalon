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
    it "should have no errors on date_issued if date_issued present" do
      mediaobject.update_attribute_in_metadata(:date_issued, '2012-12-12')
      mediaobject.should have(0).errors_on :date_issued
    end
    it "should have errors if requied fields are missing" do
      mediaobject.should have(1).errors_on(:creator)
      mediaobject.should have(1).errors_on(:title)
      mediaobject.should have(1).errors_on(:date_issued)
    end
    it "should have errors if required fields are empty" do
      mediaobject.update_attribute_in_metadata :creator, ''
      mediaobject.update_attribute_in_metadata :title, ''
      mediaobject.update_attribute_in_metadata :date_issued, ''

      mediaobject.should have(1).errors_on(:creator)
      mediaobject.should have(1).errors_on(:title)
      mediaobject.should have(1).errors_on(:date_issued)
    end
  end

  describe "Languages are handled correctly" do
    it "should handle pairs of language codes and language names" do
      mediaobject.update_datastream(:descMetadata, :language => ['eng','French','Castilian','Uyghur'])
      mediaobject.descMetadata.language_code.to_a.should =~ ['eng','fre','spa','uig']
      mediaobject.descMetadata.language_text.to_a.should =~ ['English','French','Spanish','Uighur']
    end
  end

  describe "Unknown metadata generates error" do
    it "should have an error on an unknown attribute" do
      mediaobject.update_attribute_in_metadata :foo, 'bar'
      mediaobject.should have(1).errors_on(:foo)
    end
  end

  describe "Field persistence" do
    it "should reject unknown fields"
    it "should update the contributors field" do
      load_fixture 'avalon:electronic-resource'
      mediaobject = MediaObject.find 'avalon:electronic-resource'
      mediaobject.update_attribute_in_metadata :contributor, 'Updated contributor'
      mediaobject.save

      mediaobject.contributor.length.should == 1
      mediaobject.contributor.should == ['Updated contributor']
    end

    it "should support multiple contributors" do
      load_fixture 'avalon:print-publication'
      mediaobject = MediaObject.find 'avalon:print-publication'
      mediaobject.contributor = ['Chris Colvard', 'Phuong Dinh', 'Michael Klein', 
        'Nathan Rogers']
      mediaobject.save
      mediaobject.contributor.length.should > 1
    end

    it "should support multiple publishers" do
      load_fixture 'avalon:video-segment'
      mediaobject = MediaObject.find 'avalon:video-segment'
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

  describe "discovery" do
    it "should default to discoverable" do
      @mediaobject = MediaObject.new
      @mediaobject.hidden?.should be_false
      @mediaobject.to_solr[:hidden_b].should be_false
    end

    it "should set hidden?" do
      @mediaobject = MediaObject.new
      @mediaobject.hidden = true
      @mediaobject.hidden?.should be_true
      @mediaobject.to_solr[:hidden_b].should be_true
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

    it "should default to the first workflow step" do
      mediaobject.workflow.last_completed_step.should == ['']
    end
  end

  describe 'change additional read permisions' do 
    it "should be able to have limited access" 

    it "should not add duplicated group" do
      mediaobject.access = "public"
      test_groups = ["group1", "group1", mediaobject.read_groups.first]
      mediaobject.group_exceptions = test_groups
      
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

  describe '#calculate_duration' do
    let(:media_object) { MediaObject.new }
    it 'returns zero if there are zero master files' do
      media_object.send(:calculate_duration).should == 0      
    end
    it 'returns the correct duration with two master files' do
      media_object.parts << MasterFile.new(duration: '40')
      media_object.parts << MasterFile.new(duration: '40')
      media_object.send(:calculate_duration).should == 80      
    end
    it 'returns the correct duration with two master files one nil' do
      media_object.parts << MasterFile.new(duration: '40')
      media_object.parts << MasterFile.new(duration: nil)
      media_object.send(:calculate_duration).should == 40    
    end
    it 'returns the correct duration with one master file that is nil' do
      media_object.parts << MasterFile.new(duration:nil)
      media_object.send(:calculate_duration).should == 0   
    end

  end

  describe '#populate_duration!' do
    it 'sets duration on the model' do
      media_object = MediaObject.new
      media_object.populate_duration!
      media_object.duration.should == '0'
    end
  end

  describe '#publish!' do
    let(:media_object) { MediaObject.new }
    describe 'facet' do
      it 'publishes' do
        media_object.publish!('adam@adam.com')
        media_object.to_solr[:workflow_published_facet].should == 'Published'
      end
      it 'unpublishes' do
        media_object.publish!(nil)
        media_object.to_solr[:workflow_published_facet].should == 'Unpublished'        
      end
    end
  end
end
