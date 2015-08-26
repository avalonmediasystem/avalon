# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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
  let! (:media_object) { FactoryGirl.create(:media_object) }

  describe 'validations' do
    describe 'collection' do
      it 'has errors when not present' do
        media_object.collection = nil
        media_object.valid?
        media_object.errors.should include(:collection)
      end
      it 'does not have errors when present' do
        media_object.valid?
        media_object.errors[:collection].should be_empty
      end
    end
    describe 'governing_policy' do
      it {should validate_presence_of(:governing_policy)}
    end
    describe 'language' do
      it 'should validate valid language' do
        media_object.update_datastream :descMetadata, {language: 'eng'}
        expect(media_object.valid?).to be_truthy
        expect(media_object.errors[:language]).to be_empty
      end
      it 'should not validate invalid language' do
        media_object.update_datastream :descMetadata, {language: 'engl'}
        expect(media_object.valid?).to be_falsey
        expect(media_object.errors[:language]).not_to be_empty
      end
    end
    describe 'dates' do
      let! (:valid_dates) {{
          '-9999' => ['-9999'],
          '0000' => ['0'],
          '2001' => ['2001'],
          '2001-02' => ['2001'],
          '2001-02-03' => ['2001'],
          '2001-02-03T09:30:01' => ['2001'],
          '2004-01-01T10:10:10Z' => ['2004'],
          '2004-01-01T10:10:10+05:00' => ['2004'],
          '2006/2008' => ['2006','2007','2008'],
          '2004-01-01/2005' => ['2004','2005'],
          '2005-02-01/2006-02' => ['2005','2006'],
          '2006-03-01/2007-02-08' => ['2006','2007'],
          '2007/2008-02-01' => ['2007','2008'],
          '2008-02/2009-02-01' => ['2008','2009'],
          '2009-01-04/2010-02-01' => ['2009','2010'],
          '1984?' => ['1984'],
          '1984~' => ['1984'],
          '1984?~' => ['1984'],
          '2004-06-11?' => ['2004'],
          'unknown/2006' => [],
          '2001-21' => ['2001'],
          '[1667,1668,1670..1672]' => ['1667','1668','1670','1671','1672'],
          '{1667,1668,1670..1672}' => ['1667','1668','1670','1671','1672'],
          '159u' => ['1590','1591','1592','1593','1594','1595','1596','1597','1598','1599'],
          '159u-12' => [],
          '159u-12-25' => ['1590','1591','1592','1593','1594','1595','1596','1597','1598','1599'],
          '159x' => ['1590','1591','1592','1593','1594','1595','1596','1597','1598','1599'],
          '2011-(06-04)~' => ['2011']
        }}
      it "should not accept invalid EDTF formatted dates" do
        [Faker::Lorem.sentence(4),'-999','17000'].each do |d|
          media_object.date_issued = d
          expect(media_object.valid?).to be_falsey
          expect(media_object.errors[:date_issued].present?).to be_truthy
        end
      end
      
      it "should accept valid EDTF formatted dates" do
        valid_dates.keys do |d|
          media_object.date_issued = d
          expect(media_object.valid?).to be_truthy
        end
      end
      
      it "should gather the year from a date string" do
        valid_dates.each_pair do |k,v|
          expect(media_object.descMetadata.send(:gather_years, k)).to eq v        
        end
      end 
    end

    describe 'notes' do
      it 'should validate notes with types in controlled vocabulary' do
        media_object.update_datastream :descMetadata, {note: ['Test Note'], note_type: ['general']}
        expect(media_object.valid?).to be_truthy
        expect(media_object.errors[:note]).to be_empty
      end
      it 'should not validate notes with types not in controlled vocabulary' do
        media_object.update_datastream :descMetadata, {note: ['Test Note'], note_type: ['genreal']}
        expect(media_object.valid?).to be_falsey
        expect(media_object.errors[:note]).not_to be_empty
      end
    end
  end

  describe 'delegators' do
    it 'correctly sets the creator' do
      media_object.creator = ['Creator, Joan']
      media_object.creator.should include('Creator, Joan')
      media_object.descMetadata.creator.should include('Creator, Joan')
    end
  end

  describe 'abilities' do
    let (:collection) { media_object.collection.reload } 

    context 'when manager' do
      subject{ ability}
      let(:ability){ Ability.new(User.where(username: collection.managers.first).first) }

      it{ should be_able_to(:create, MediaObject) }
      it{ should be_able_to(:read, media_object) }
      it{ should be_able_to(:update, media_object) }
      it{ should be_able_to(:destroy, media_object) }
      it{ should be_able_to(:inspect, media_object) }
      it "should be able to destroy and unpublish published item" do
        media_object.publish! "someone"
        subject.should be_able_to(:destroy, media_object)
        subject.should be_able_to(:unpublish, media_object)
      end

      context 'and logged in through LTI' do
        let(:ability){ Ability.new(User.where(username: collection.managers.first).first, {full_login: false, virtual_groups: [Faker::Lorem.word]}) }

        it{ should_not be_able_to(:share, MediaObject) }
        it{ should_not be_able_to(:update, media_object) }
        it{ should_not be_able_to(:destroy, media_object) }
      end
    end

    context 'when editor' do
      subject{ ability}
      let(:ability){ Ability.new(User.where(username: collection.editors.first).first) }

      it{ should be_able_to(:create, MediaObject) }
      it{ should be_able_to(:read, media_object) }
      it{ should be_able_to(:update, media_object) }
      it{ should be_able_to(:destroy, media_object) }
      it{ should be_able_to(:update_access_control, media_object) }
      it "should not be able to destroy and unpublish published item" do
        media_object.publish! "someone"
        subject.should_not be_able_to(:destroy, media_object)
        subject.should_not be_able_to(:update, media_object)
        subject.should_not be_able_to(:update_access_control, media_object)
        subject.should_not be_able_to(:unpublish, media_object)
      end
    end

    context 'when depositor' do
      subject{ ability }
      let(:ability){ Ability.new(User.where(username: collection.depositors.first).first) }

      it{ should be_able_to(:create, MediaObject) }
      it{ should be_able_to(:read, media_object) }
      it{ should be_able_to(:update, media_object) }
      it{ should be_able_to(:destroy, media_object) }
      it "should not be able to destroy and unpublish published item" do
        media_object.publish! "someone"
        subject.should_not be_able_to(:destroy, media_object)
        subject.should_not be_able_to(:unpublish, media_object)
      end
      it{ should_not be_able_to(:update_access_control, media_object) }
    end

    context 'when end-user' do
      subject{ ability }
      let(:ability){ Ability.new(user) }
      let(:user){FactoryGirl.create(:user)}

      it{ should be_able_to(:share, MediaObject) }
      it "should not be able to read unauthorized, published MediaObject" do
        media_object.avalon_publisher = "random"
        media_object.save
        subject.can?(:read, media_object).should be false
      end

      it "should not be able to read authorized, unpublished MediaObject" do
        media_object.read_users += [user.user_key]
        media_object.should_not be_published
        subject.can?(:read, media_object).should be false
      end

      it "should be able to read authorized, published MediaObject" do
        media_object.read_users += [user.user_key]
        media_object.publish! "random"
        subject.can?(:read, media_object).should be true
      end
    end

    context 'when lti user' do
      subject{ ability }
      let(:user){ FactoryGirl.create(:user_lti) }
      let(:ability){ Ability.new(user, {full_login: false, virtual_groups: [Faker::Lorem.word]}) }

      it{ should_not be_able_to(:share, MediaObject) }
    end
  end

  describe "Required metadata is present" do
    it {should validate_presence_of(:creator)}
    it {should validate_presence_of(:date_issued)}
    it {should validate_presence_of(:title)}
  end

  describe "Languages are handled correctly" do
    it "should handle pairs of language codes and language names" do
      media_object.update_datastream(:descMetadata, :language => ['eng','French','spa','uig'])
      media_object.descMetadata.language_code.to_a.should =~ ['eng','fre','spa','uig']
      media_object.descMetadata.language_text.to_a.should =~ ['English','French','Spanish','Uighur']
    end
  end

  describe "Unknown metadata generates error" do
    it "should have an error on an unknown attribute" do
      media_object.update_attribute_in_metadata :foo, 'bar'
      media_object.valid?
      expect(media_object.errors[:foo].size).to eq(1)
    end
  end

  describe "Field persistence" do
    skip "setters should work"
    xit "should reject unknown fields"
    xit "should update the contributors field" do
      contributor =  'Nathan Rogers'
      media_object.contributor = contributor
      media_object.save

      media_object.contributor.length.should == 1
      media_object.contributor.should == [contributor]
    end

    xit "should support multiple contributors" do
      contributors =  ['Chris Colvard', 'Phuong Dinh', 'Michael Klein', 'Nathan Rogers']
      media_object.contributor = contributors
      media_object.save
      media_object.contributor.length.should > 1
      media_object.contrinbutor.should == contributors
    end

    xit "should support multiple publishers" do
      media_object.publisher = ['Indiana University']
      media_object.publisher.length.should == 1
      
      publishers = ['Indiana University', 'Northwestern University', 'Ohio State University', 'Notre Dame']
      media_object.publisher = publishers
      media_object.save
      media_object.publisher.length.should > 1
      media_object.publisher.should == publishers
    end
  end
  
  describe "Update datastream" do
    it "should handle a complex update" do
      params = {
        'creator'     => [Faker::Name.name, Faker::Name.name],
        'contributor' => [Faker::Name.name, Faker::Name.name, Faker::Name.name],
        'title'       => Faker::Lorem.sentence,
        'date_issued' => '2013',
        'date_created'=> '1956'
      }
      media_object.update_datastream(:descMetadata, params)
      media_object.creator.should      == params['creator']
      media_object.contributor.should  == params['contributor']
      media_object.title.should        == params['title']
      media_object.date_issued.should  == params['date_issued']
      media_object.date_created.should == params['date_created']
    end
  end

  describe "Update datastream directly" do
    it "should reflect datastream changes on media object" do
      newtitle = Faker::Lorem.sentence
      media_object.descMetadata.add_bibliographic_id('ABC123','local')
      media_object.save
      media_object.reload
      expect(media_object.bibliographic_id).to eq(["local","ABC123"])
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

  describe '#finished_processing?' do
    it 'returns true if the statuses indicate processing is finished' do
      media_object.parts << MasterFile.new(status_code: 'CANCELLED')
      media_object.parts << MasterFile.new(status_code: 'COMPLETED')
      media_object.finished_processing?.should be true
    end
    it 'returns true if the statuses indicate processing is not finished' do
      media_object.parts << MasterFile.new(status_code: 'CANCELLED')
      media_object.parts << MasterFile.new(status_code: 'RUNNING')
      media_object.finished_processing?.should be false
    end
  end

  describe '#calculate_duration' do
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

  describe '#destroy' do
    it 'destroys related masterfiles' do
      media_object.parts << FactoryGirl.create(:master_file)
      master_file_pids = media_object.parts.map(&:id)
      media_object.section_pid = master_file_pids
      media_object.save( validate: false )
      media_object.destroy
      MasterFile.exists?(master_file_pids.first).should == false
    end
  end

  describe '#set_duration!' do
    it 'sets duration on the model' do
      media_object.set_duration!
      media_object.duration.should == '0'
    end
  end

  describe '#set_media_types!' do
    let!(:master_file) { FactoryGirl.create(:master_file, mediaobject: media_object) }
    it 'sets format on the model' do
      expect(media_object.format).to be nil
      media_object.set_media_types!
      expect(media_object.format).to eq "video/mp4"
    end
  end

  describe '#set_resource_types!' do
    let!(:master_file) { FactoryGirl.create(:master_file, mediaobject: media_object) }
    it 'sets resource_type on the model' do
      expect(media_object.descMetadata.resource_type).to eq []
      media_object.set_resource_types!
      expect(media_object.descMetadata.resource_type).to eq ["moving image"]
    end
  end
 
  describe '#publish!' do
    describe 'facet' do
      it 'publishes' do
        media_object.publish!('adam@adam.com')
        media_object.to_solr["workflow_published_sim"].should == 'Published'
      end
      it 'unpublishes' do
        media_object.publish!(nil)
        media_object.to_solr["workflow_published_sim"].should == 'Unpublished'        
      end
    end
  end

  describe 'indexing' do
    it 'uses stringified keys for everything except :id' do
      media_object.to_solr.keys.reject { |k| k.is_a?(String) }.should == [:id]
    end
    it 'should not index any unknown resource types' do
      media_object.descMetadata.resource_type = 'notated music'
      expect(media_object.to_solr['format_sim']).not_to include 'Notated Music'
    end
    it 'should index separate identifiers as separate values' do
      media_object.descMetadata.add_other_identifier('12345678','lccn')
      media_object.descMetadata.add_other_identifier('8675309 testing','local')
      solr_doc = media_object.to_solr
      expect(solr_doc['other_identifier_sim']).to include('12345678','8675309 testing')
      expect(solr_doc['other_identifier_sim']).not_to include('123456788675309 testing')
    end
  end

  describe 'permalink' do

    let(:media_object){ FactoryGirl.build(:media_object) }

    before(:each) {
      Permalink.on_generate{ |obj,target| 'http://www.example.com/perma-url' }
    }

    context 'unpublished' do
      it 'is empty when unpublished' do
        media_object.permalink.should be_blank
      end
    end

    context 'published' do
      
      before(:each){ media_object.publish!('C.S. Lewis') } # saves the object

      it 'responds to permalink' do
        media_object.respond_to?(:permalink).should be true
      end

      it 'sets the permalink on the object' do
        media_object.permalink.should_not be_nil
      end

      it 'sets the correct permalink' do
        media_object.permalink.should == 'http://www.example.com/perma-url'
      end

      it 'does not remove the permalink if the permalink service returns nil' do
        Permalink.on_generate{ nil }
        media_object.save( validate: false )
        media_object.permalink.should == 'http://www.example.com/perma-url'
      end

    end

    context 'correct target' do

      it 'should link to the correct target' do
        media_object.save(validate: false)
        t = nil
        Permalink.on_generate { |obj, target|
          t = target
          'http://www.example.com/perma-url'
        }
        media_object.ensure_permalink!
        t.should == "http://test.host/media_objects/#{media_object.pid}"
        media_object.permalink.should == 'http://www.example.com/perma-url'
      end

    end

    context 'error handling' do

      it 'logs an error when the permalink service returns an exception' do
        Permalink.on_generate{ 1 / 0 }
        Rails.logger.should_receive(:error)
        media_object.ensure_permalink!
      end

    end

    describe "#ensure_permalink!" do
      it 'is not called when the object is not persisted' do
        media_object.should_not_receive(:ensure_permalink!)
        media_object.save
      end
    end


    describe '#ensure_permalink!' do
      it 'returns true when updated' do
        media_object.should_receive(:ensure_permalink!).at_least(1).times.and_return(false)
        media_object.publish!('C.S. Lewis')
      end 

      it 'returns false when not updated' do
        media_object.publish!('C.S. Lewis')
        media_object.should_receive(:ensure_permalink!).and_return(false)
        media_object.save( validate: false )
      end
    end
  end

  describe 'bib import' do
    let(:bib_id) { '7763100' }
    let(:mods) { File.read(File.expand_path("../../fixtures/#{bib_id}.mods",__FILE__)) }
    before do
      media_object.update_attribute_in_metadata(:resource_type, ["moving image"])
      media_object.update_attribute_in_metadata(:format, "video/mpeg")
      instance = double("instance")
      allow(Avalon::BibRetriever).to receive(:instance).and_return(instance)
      allow(Avalon::BibRetriever.instance).to receive(:get_record).and_return(mods)
    end

    it 'should not override format' do
      expect { media_object.descMetadata.populate_from_catalog!(bib_id, 'local') }.to_not change { media_object.format }
    end
    it 'should not override resource_type' do
      expect { media_object.descMetadata.populate_from_catalog!(bib_id, 'local') }.to_not change { media_object.resource_type }
    end
  end
end
