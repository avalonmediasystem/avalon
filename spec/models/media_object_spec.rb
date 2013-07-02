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
require 'cancan/matchers'

describe MediaObject do
  let (:media_object) { MediaObject.create }

  describe 'validations' do
    before do 
      media_object.valid?
    end

    describe 'collection present' do
      it 'has error when not present' do
        media_object.valid?
        media_object.errors.should include(:collection)
      end
      it 'does not have error when present' do
        media_object.collection = FactoryGirl.build(:collection)
        media_object.valid?
        media_object.errors[:collection].should be_empty
      end
    end
  end

  describe 'abilities' do
    let (:collection) { FactoryGirl.create(:collection) } 
    let (:media_object2) { MediaObject.new }
    let (:collection2) { Collection.new } 

    before :each do 
      media_object.collection = collection
      media_object2.collection = collection2
    end

    context 'when manager' do
      subject{ ability}
      let(:ability){ Ability.new(User.where(username: collection.managers.first).first) }

      it{ should be_able_to(:create, MediaObject) }
      it{ should be_able_to(:update, media_object) }
      it{ should be_able_to(:destroy, media_object) }
      it{ should be_able_to(:update, media_object) }
    end

    context 'when editor' do
      subject{ ability}
      let(:ability){ Ability.new(User.where(username: collection.editors.first).first) }

      it{ should be_able_to(:create, MediaObject) }
      it{ should be_able_to(:update, media_object) }
      it{ should be_able_to(:destroy, media_object) }
      it "should not be able to destroy published item" do
        media_object.avalon_publisher = "someone"
        media_object.save(validate: false)
        ability.should_not be_able_to(:destroy, media_object)
      end
    end

    context 'when depositor' do
      subject{ ability}
      let(:ability){ Ability.new(User.where(username: collection.depositors.first).first) }

      it{ should be_able_to(:create, MediaObject) }
      it{ should be_able_to(:update, media_object) }
      it{ should be_able_to(:destroy, media_object) }
      it "should not be able to destroy published item" do
        media_object.avalon_publisher = "someone"
        media_object.save(validate: false)
        subject.should_not be_able_to(:destroy, media_object)
      end
      it "should not be able to change access control" do
        subject.cannot(:update_access_control, media_object).should be_true
      end
    end
  end

  describe "Required metadata is present" do
    it {should validate_presence_of(:creator)}
    it {should validate_presence_of(:date_issued)}
    it {should validate_presence_of(:title)}
  end

  describe "Languages are handled correctly" do
    it "should handle pairs of language codes and language names" do
      media_object.update_datastream(:descMetadata, :language => ['eng','French','Castilian','Uyghur'])
      media_object.descMetadata.language_code.to_a.should =~ ['eng','fre','spa','uig']
      media_object.descMetadata.language_text.to_a.should =~ ['English','French','Spanish','Uighur']
    end
  end

  describe "Unknown metadata generates error" do
    it "should have an error on an unknown attribute" do
      media_object.update_attribute_in_metadata :foo, 'bar'
      media_object.should have(1).errors_on(:foo)
    end
  end

  describe "Field persistence" do
    it "should reject unknown fields"
    it "should update the contributors field" do
      load_fixture 'avalon:electronic-resource'
      media_object = MediaObject.find 'avalon:electronic-resource'
      media_object.update_attribute_in_metadata :contributor, 'Updated contributor'
      media_object.save

      media_object.contributor.length.should == 1
      media_object.contributor.should == ['Updated contributor']
    end

    it "should support multiple contributors" do
      load_fixture 'avalon:print-publication'
      media_object = MediaObject.find 'avalon:print-publication'
      media_object.contributor = ['Chris Colvard', 'Phuong Dinh', 'Michael Klein', 
        'Nathan Rogers']
      media_object.save
      media_object.contributor.length.should > 1
    end

    it "should support multiple publishers" do
      load_fixture 'avalon:video-segment'
      media_object = MediaObject.find 'avalon:video-segment'
      media_object.publisher.length.should == 1
      
      media_object.publisher = ['Indiana University', 'Northwestern University',
        'Ohio State University', 'Notre Dame']
      media_object.save
      media_object.publisher.length.should > 1
    end
  end
  
  describe "Valid formats" do
    it "should only accept ISO formatted dates"
  end
  
  describe "access" do
    it "should set access level to public" do
      media_object = MediaObject.new
      media_object.access = "public"
      media_object.read_groups.should =~ ["public", "registered"]
    end
    it "should set access level to restricted" do
      media_object = MediaObject.new
      media_object.access = "restricted"
      media_object.read_groups.should =~ ["registered"]
    end
    it "should set access level to private" do
      media_object = MediaObject.new
      media_object.access = "private"
      media_object.read_groups.should =~ []
    end
    it "should return public" do
      media_object = MediaObject.new
      media_object.read_groups = ["public", "registered"]
      media_object.access.should eq "public"
    end
    it "should return restricted" do
      media_object = MediaObject.new
      media_object.read_groups = ["registered"]
      media_object.access.should eq "restricted"
    end
    it "should return private" do
      media_object = MediaObject.new
      media_object.read_groups = []
      media_object.access.should eq "private"
    end
  end

  describe "discovery" do
    it "should default to discoverable" do
      @media_object = MediaObject.new
      @media_object.hidden?.should be_false
      @media_object.to_solr[:hidden_b].should be_false
    end

    it "should set hidden?" do
      @media_object = MediaObject.new
      @media_object.hidden = true
      @media_object.hidden?.should be_true
      @media_object.to_solr[:hidden_b].should be_true
    end
  end

  describe "Ingest status" do
    it "should default to unpublished" do
      media_object.workflow.published.first.should eq "false"
      media_object.workflow.published?.should eq false
    end

    it "should be published when the item is visible" do
      media_object.workflow.publish

      media_object.workflow.published.should == ['true'] 
      media_object.workflow.last_completed_step.first.should == HYDRANT_STEPS.last.step
    end

    it "should recognize the current step" do
      media_object.workflow.last_completed_step = 'structure'
      media_object.workflow.current?('access-control').should == true
    end

    it "should default to the first workflow step" do
      media_object.workflow.last_completed_step.should == ['']
    end
  end

  describe 'change additional read permisions' do 
    it "should be able to have limited access" 

    it "should not add duplicated group" do
      media_object.access = "public"
      test_groups = ["group1", "group1", media_object.read_groups.first]
      media_object.group_exceptions = test_groups
      
      media_object.read_groups.should eql media_object.read_groups.uniq
    end
  end

  describe '#finished_processing?' do
    it 'returns true if the statuses indicate processing is finished' do
      media_object = MediaObject.new
      media_object.parts << MasterFile.new(status_code: ['STOPPED'])
      media_object.parts << MasterFile.new(status_code: ['SUCCEEDED'])
      media_object.finished_processing?.should be_true
    end
    it 'returns true if the statuses indicate processing is not finished' do
      media_object = MediaObject.new
      media_object.parts << MasterFile.new(status_code: ['STOPPED'])
      media_object.parts << MasterFile.new(status_code: ['RUNNING'])
      media_object.finished_processing?.should be_false
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
