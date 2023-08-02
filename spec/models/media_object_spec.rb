# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

require 'rails_helper'
require 'cancan/matchers'

describe MediaObject do
  let(:media_object) { FactoryBot.create(:media_object) }

  it 'assigns a noid id' do
    media_object = MediaObject.new
    expect { media_object.assign_id! }.to change { media_object.id }.from(nil).to(String)
  end

  describe 'find' do
    it 'returns an object' do
      expect(MediaObject.find(media_object.id)).to eq media_object
    end
    context 'with trailing slash' do
      it 'returns an object' do
        expect(MediaObject.find(media_object.id + '/')).to eq media_object
      end
    end
  end

  describe 'validations' do
    # Force the validations to run by being on the resource-description workflow step
    let(:media_object) { FactoryBot.build(:media_object).tap {|mo| mo.workflow.last_completed_step = "resource-description"} }

    describe 'collection' do
      it 'has errors when not present' do
        expect{media_object.collection = nil}.to raise_error(ActiveFedora::AssociationTypeMismatch)
      end
      it 'does not have errors when present' do
        media_object.valid?
        expect(media_object.errors[:collection]).to be_empty
      end
    end
    describe 'governing_policy' do
      xit {is_expected.to validate_presence_of(:governing_policies)}
    end
    describe 'language' do
      it 'should validate valid language' do
        media_object.language = ['eng']
        expect(media_object.valid?).to be_truthy
        expect(media_object.errors[:language]).to be_empty
      end
      it 'should not validate invalid language' do
        media_object.language = ['engl']
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
          'unknown/2006' => ['Unknown'],
          '2006/unknown' => ['Unknown'],
          '2001-21' => ['2001'],
          '[1667,1668,1670..1672]' => ['1667','1668','1670','1671','1672'],
          '{1667,1668,1670..1672}' => ['1667','1668','1670','1671','1672'],
          '159u' => ['1590','1591','1592','1593','1594','1595','1596','1597','1598','1599'],
          '159u-12' => ['1590','1591','1592','1593','1594','1595','1596','1597','1598','1599'],
          '159u-12-25' => ['1590','1591','1592','1593','1594','1595','1596','1597','1598','1599'],
          '159x' => ['1590','1591','1592','1593','1594','1595','1596','1597','1598','1599'],
          '2011-(06-04)~' => ['2011'],
          'unknown/unknown' => ['Unknown']
        }}
      it "should not accept invalid EDTF formatted dates" do
        [Faker::Lorem.sentence(word_count: 4),'-999','17000'].each do |d|
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
        media_object.descMetadata.note = ['Test Note']
        media_object.descMetadata.note.type = ['general']
        expect(media_object.valid?).to be_truthy
        expect(media_object.errors[:note]).to be_empty
      end
      it 'should not validate notes with types not in controlled vocabulary' do
        media_object.descMetadata.note = ['Test Note']
        media_object.descMetadata.note.type = ['genereal']
        expect(media_object.valid?).to be_falsey
        expect(media_object.errors[:note]).not_to be_empty
      end
    end
  end

  describe 'delegators' do
    it 'correctly sets the creator' do
      media_object.creator = ['Creator, Joan']
      expect(media_object.creator).to include('Creator, Joan')
      expect(media_object.descMetadata.creator).to include('Creator, Joan')
    end
  end

  describe 'abilities' do
    let (:collection) { media_object.collection.reload }

    context 'when manager' do
      subject{ ability}
      let(:ability){ Ability.new(User.where(Devise.authentication_keys.first => collection.managers.first).first) }

      it{ is_expected.to be_able_to(:create, MediaObject) }
      it{ is_expected.to be_able_to(:read, media_object) }
      it{ is_expected.to be_able_to(:update, media_object) }
      it{ is_expected.to be_able_to(:destroy, media_object) }
      it{ is_expected.to be_able_to(:inspect, media_object) }
      it "should be able to destroy and unpublish published item" do
        media_object.publish! "someone"
        expect(subject).to be_able_to(:destroy, media_object)
        expect(subject).to be_able_to(:unpublish, media_object)
      end

      context 'and logged in through LTI' do
        let(:ability){ Ability.new(User.where(Devise.authentication_keys.first => collection.managers.first).first, {full_login: false, virtual_groups: [Faker::Lorem.word]}) }

        it{ is_expected.not_to be_able_to(:share, MediaObject) }
        it{ is_expected.not_to be_able_to(:update, media_object) }
        it{ is_expected.not_to be_able_to(:destroy, media_object) }
      end
    end

    context 'when editor' do
      subject{ ability}
      let(:ability){ Ability.new(User.where(Devise.authentication_keys.first => collection.editors.first).first) }

      it{ is_expected.to be_able_to(:create, MediaObject) }
      it{ is_expected.to be_able_to(:read, media_object) }
      it{ is_expected.to be_able_to(:update, media_object) }
      it{ is_expected.to be_able_to(:destroy, media_object) }
      it{ is_expected.to be_able_to(:update_access_control, media_object) }
      it "should not be able to destroy and unpublish published item" do
        media_object.publish! "someone"
        expect(subject).not_to be_able_to(:destroy, media_object)
        expect(subject).not_to be_able_to(:update, media_object)
        expect(subject).not_to be_able_to(:update_access_control, media_object)
        expect(subject).not_to be_able_to(:unpublish, media_object)
      end
    end

    context 'when depositor' do
      subject{ ability }
      let(:ability){ Ability.new(User.where(Devise.authentication_keys.first => collection.depositors.first).first) }

      it{ is_expected.to be_able_to(:create, MediaObject) }
      it{ is_expected.to be_able_to(:read, media_object) }
      it{ is_expected.to be_able_to(:update, media_object) }
      it{ is_expected.to be_able_to(:destroy, media_object) }
      it "should not be able to destroy and unpublish published item" do
        media_object.publish! "someone"
        expect(subject).not_to be_able_to(:destroy, media_object)
        expect(subject).not_to be_able_to(:unpublish, media_object)
      end
      it{ is_expected.not_to be_able_to(:update_access_control, media_object) }
    end

    context 'when end-user' do
      subject{ ability }
      let(:ability){ Ability.new(user) }
      let(:user){FactoryBot.create(:user)}
      before do
        media_object.save!
      end

      it{ is_expected.to be_able_to(:share, MediaObject) }
      it "should not be able to read unauthorized, published MediaObject" do
        media_object.publish! "random"
        media_object.reload
        expect(subject.can?(:read, media_object)).to be false
      end

      it "should not be able to read authorized, unpublished MediaObject" do
        media_object.read_users += [user.user_key]
        expect(media_object).not_to be_published
        expect(subject.can?(:read, media_object)).to be false
      end

      it "should be able to read authorized, published MediaObject" do
        media_object.read_users += [user.user_key]
        media_object.publish! "random"
        media_object.reload
        expect(subject.can?(:read, media_object)).to be true
      end
    end

    context 'when lti user' do
      subject{ ability }
      let(:user){ FactoryBot.create(:user_lti) }
      let(:ability){ Ability.new(user, {full_login: false, virtual_groups: [Faker::Lorem.word]}) }

      it{ is_expected.not_to be_able_to(:share, MediaObject) }
    end

    context 'when ip address' do
      subject{ ability }
      let(:user) { FactoryBot.create(:user) }
      let(:ip_addr) { Faker::Internet.ip_v4_address }
      let(:ability) { Ability.new(user, {remote_ip: ip_addr}) }
      before do
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(ip_addr)
      end

      it 'should not be able to read unauthorized, published MediaObject' do
        media_object.read_groups += [Faker::Internet.ip_v4_address]
        media_object.publish! "random"
        media_object.reload
        expect(subject.can?(:read, media_object)).to be_falsey
      end
      it 'should be able to read single-ip authorized, published MediaObject' do
        media_object.read_groups += [ip_addr]
        media_object.publish! "random"
        media_object.reload
        expect(subject.can?(:read, media_object)).to be_truthy
      end
      it 'should be able to read ip-range authorized, published MediaObject' do
        media_object.read_groups += ["#{ip_addr}/30"]
        media_object.publish! "random"
        media_object.reload
        expect(subject.can?(:read, media_object)).to be_truthy
      end
    end
  end

  describe "Required metadata is present" do
    # Force the validations to run by being on the resource-description workflow step
    subject(:media_object) { FactoryBot.build(:media_object).tap {|mo| mo.workflow.last_completed_step = "resource-description"} }

    it {is_expected.to validate_presence_of(:date_issued)}
    it {is_expected.to validate_presence_of(:title)}
  end

  describe "Languages are handled correctly" do
    it "should handle pairs of language codes and language names" do
      media_object.language = ['eng','French','spa','uig']
      expect(media_object.descMetadata.language_code.to_a).to match_array(['eng','fre','spa','uig'])
      expect(media_object.descMetadata.language_text.to_a).to match_array(['English','French','Spanish','Uighur'])
    end
  end

  # describe "Unknown metadata generates error" do
  #   it "should have an error on an unknown attribute" do
  #     media_object.update_attribute_in_metadata :foo, 'bar'
  #     media_object.valid?
  #     expect(media_object.errors[:foo].size).to eq(1)
  #   end
  # end

  describe "Field persistence" do
    skip "setters should work"
    xit "should reject unknown fields"
    xit "should update the contributors field" do
      contributor =  'Nathan Rogers'
      media_object.contributor = contributor
      media_object.save

      expect(media_object.contributor.length).to eq(1)
      expect(media_object.contributor).to eq([contributor])
    end

    xit "should support multiple contributors" do
      contributors =  ['Chris Colvard', 'Phuong Dinh', 'Michael Klein', 'Nathan Rogers']
      media_object.contributor = contributors
      media_object.save
      expect(media_object.contributor.length).to be > 1
      expect(media_object.contrinbutor).to eq(contributors)
    end

    xit "should support multiple publishers" do
      media_object.publisher = ['Indiana University']
      expect(media_object.publisher.length).to eq(1)

      publishers = ['Indiana University', 'Northwestern University', 'Ohio State University', 'Notre Dame']
      media_object.publisher = publishers
      media_object.save
      expect(media_object.publisher.length).to be > 1
      expect(media_object.publisher).to eq(publishers)
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
      media_object.update_attributes(params)
      expect(media_object.creator).to      eq(params['creator'])
      expect(media_object.contributor).to  eq(params['contributor'])
      expect(media_object.title).to        eq(params['title'])
      expect(media_object.date_issued).to  eq(params['date_issued'])
      expect(media_object.date_created).to eq(params['date_created'])
    end
  end

  describe "Update datastream with empty strings" do
    it "should remove pre-existing values" do
      media_object = FactoryBot.create( :fully_searchable_media_object )
      params = {
        'alternative_title' => [''],
        'translated_title' => [''],
        'uniform_title' => [''],
        'creator' => [''],
        'format' => [''],
        'contributor' => [''],
        'publisher' => [''],
        'subject' => [''],
        'related_item_url' => [{label:'',url:''}],
        'geographic_subject' => [''],
        'temporal_subject' => [''],
        'topical_subject' => [''],
        'language' => [''],
        'table_of_contents' => [''],
        'physical_description' => [''],
        'record_identifier' => [''],
        'note' => [{type:'',note:''}],
        'other_identifier' => [{id:'',source:''}]
      }
      media_object.assign_attributes(params)
      expect(media_object.alternative_title).to eq([])
      expect(media_object.translated_title).to eq([])
      expect(media_object.uniform_title).to eq([])
      expect(media_object.creator).to eq([])
      expect(media_object.format).to eq([])
      expect(media_object.contributor).to eq([])
      expect(media_object.publisher).to eq([])
      expect(media_object.subject).to eq([])
      expect(media_object.related_item_url).to eq([])
      expect(media_object.geographic_subject).to eq([])
      expect(media_object.temporal_subject).to eq([])
      expect(media_object.topical_subject).to eq([])
      expect(media_object.language).to eq([])
      expect(media_object.table_of_contents).to eq([])
      expect(media_object.physical_description).to eq([])
      expect(media_object.record_identifier).to eq([])
      expect(media_object.note).to eq([])
      expect(media_object.other_identifier).to eq([])
   end
  end

  describe "Update datastream directly" do
    it "should reflect datastream changes on media object" do
      media_object.descMetadata.add_bibliographic_id('ABC123','local')
      media_object.save
      media_object.reload
      expect(media_object.bibliographic_id).to eq({source: "local", id: 'ABC123'})
    end
  end

  describe "Correctly set table of contents from form" do
    it "should not include empty strings" do
      media_object.update_attributes({'table_of_contents' => ['']})
      expect(media_object.table_of_contents).to eq([])
    end
    it "should include actual strings" do
      media_object.update_attributes({'table_of_contents' => ['Test']})
      expect(media_object.table_of_contents).to eq(['Test'])
    end
  end

  describe "Bibliographic Identifiers" do
    it "should exclude recordIdentifier[@source = Fedora or Fedora4]" do
      media_object.descMetadata.add_bibliographic_id('ABC123','local')
      media_object.descMetadata.add_bibliographic_id('DEF456','Fedora')
      media_object.descMetadata.add_bibliographic_id('GHI789','Fedora4')
      media_object.save
      media_object.reload
      expect(media_object.bibliographic_id).to eq({source: "local", id: 'ABC123'})
    end
  end

  describe "Update datastream with more than one originInfo element" do
    it "shouldn't error out" do
      media_object.date_created = '2016'
      media_object.date_issued = nil
      media_object.descMetadata.ng_xml.root.add_child('<originInfo/>')
      expect { media_object.date_issued = '2017' }.not_to raise_error
      expect(media_object.date_created).to eq '2016'
      expect(media_object.date_issued).to eq '2017'
    end
  end

  describe "Ingest status" do
    it "should default to unpublished" do
      expect(media_object.workflow.published.first).to eq "false"
      expect(media_object.workflow.published?).to eq false
    end

    it "should be published when the item is visible" do
      media_object.workflow.publish

      expect(media_object.workflow.published).to eq(['true'])
      expect(media_object.workflow.last_completed_step.first).to eq(HYDRANT_STEPS.last.step)
    end

    it "should recognize the current step" do
      media_object.workflow.last_completed_step = 'structure'
      expect(media_object.workflow.current?('access-control')).to eq(true)
    end

    it "should default to the first workflow step" do
      expect(media_object.workflow.last_completed_step).to eq([''])
    end
  end

  describe '#finished_processing?' do
    it 'returns true if the statuses indicate processing is finished' do
      media_object.ordered_master_files += [FactoryBot.create(:master_file, :cancelled_processing)]
      media_object.ordered_master_files += [FactoryBot.create(:master_file, :completed_processing)]
      expect(media_object.finished_processing?).to be true
    end
    it 'returns true if the statuses indicate processing is not finished' do
      media_object.ordered_master_files += [FactoryBot.create(:master_file, :cancelled_processing)]
      media_object.ordered_master_files += [FactoryBot.create(:master_file)]
      expect(media_object.finished_processing?).to be false
    end
  end

  describe '#calculate_duration' do
    let(:master_file1) { FactoryBot.create(:master_file, media_object: media_object, duration: '40') }
    let(:master_file2) { FactoryBot.create(:master_file, media_object: media_object, duration: '40') }
    let(:master_file3) { FactoryBot.create(:master_file, media_object: media_object, duration: nil) }
    let(:master_files) { [] }

    before do
      master_files
      # Explicitly run indexing job to ensure fields are indexed for structure searching
      MediaObjectIndexingJob.perform_now(media_object.id)
    end

    context 'with zero master files' do
      it 'returns zero' do
	expect(media_object.send(:calculate_duration)).to eq(0)
      end
    end
    context 'with two master files' do
      let(:master_files) { [master_file1, master_file2] }
      it 'returns the correct duration' do
	expect(media_object.send(:calculate_duration)).to eq(80)
      end
    end
    context 'with two master files one nil' do
      let(:master_files) { [master_file1, master_file3] }
      it 'returns the correct duration' do
	expect(media_object.send(:calculate_duration)).to eq(40)
      end
    end
    context 'with one master file that is nil' do
      let(:master_files) { [master_file3] }
      it 'returns the correct duration' do
	expect(media_object.send(:calculate_duration)).to eq(0)
      end
    end
  end

  describe '#destroy' do
    let(:media_object) { FactoryBot.create(:media_object, :with_master_file) }
    let(:master_file) { media_object.master_files.first }

    before do
      allow(master_file).to receive(:stop_processing!)
    end

    it 'destroys related master_files' do
      expect { media_object.destroy }.to change { MasterFile.exists?(master_file) }.from(true).to(false)
    end

    it 'destroys multiple sections' do
      FactoryBot.create(:master_file, media_object: media_object)
      media_object.reload
      expect(media_object.master_files.size).to eq 2
      media_object.master_files.each do |mf|
        allow(mf).to receive(:stop_processing!)
      end
      expect { media_object.destroy }.to change { MasterFile.count }.from(2).to(0)
      expect(MediaObject.exists?(media_object.id)).to be_falsey
    end
  end

  context "dependent properties" do
    describe '#set_duration!' do
      it 'sets duration on the model' do
        media_object.set_duration!
        expect(media_object.duration).to eq('0')
      end
    end

    describe '#set_media_types!' do
      let(:media_object) { FactoryBot.create(:media_object, :with_master_file) }
      it 'sets format on the model' do
        media_object.format = nil
        expect(media_object.format).to be_empty
        media_object.set_media_types!
        expect(media_object.format).to eq ["video/mp4"]
      end
    end

    describe '#set_resource_types!' do
      let!(:master_file) { FactoryBot.create(:master_file, media_object: media_object) }
      before do
        media_object.reload
      end
      it 'sets resource_type on the model' do
        media_object.avalon_resource_type = []
        expect(media_object.avalon_resource_type).to be_empty
        media_object.set_resource_types!
        expect(media_object.avalon_resource_type).to eq ["moving image"]
      end
    end
  end

  describe '#publish!' do
    describe 'facet' do
      it 'publishes' do
        media_object.publish!('adam@adam.com')
        expect(media_object.to_solr["workflow_published_sim"]).to eq('Published')
      end
      it 'unpublishes' do
        media_object.publish!(nil)
        expect(media_object.to_solr["workflow_published_sim"]).to eq('Unpublished')
      end
      context 'validate: false' do
        it 'publishes' do
          media_object.publish!('adam@adam.com', validate: false)
          expect(media_object.to_solr["workflow_published_sim"]).to eq('Published')
        end
        it 'unpublishes' do
          media_object.publish!(nil, validate: false)
          expect(media_object.to_solr["workflow_published_sim"]).to eq('Unpublished')
        end
        it 'raises runtime error if save fails' do
          allow_any_instance_of(MediaObject).to receive(:save).and_return(false)
          expect { media_object.publish!(nil, validate: false) }.to raise_error(RuntimeError)
        end
      end
    end
  end

  describe 'indexing' do
    it 'uses stringified keys for everything except :id' do
      expect(media_object.to_solr.keys.reject { |k| k.is_a?(String) }).to eq([:id])
    end
    it 'should not index any unknown resource types' do
      media_object.resource_type = 'notated music'
      expect(media_object.to_solr['format_sim']).not_to include 'Notated Music'
    end
    it 'should index separate identifiers as separate values' do
      media_object.descMetadata.add_other_identifier('12345678','lccn')
      media_object.descMetadata.add_other_identifier('8675309 testing','local')
      solr_doc = media_object.to_solr
      expect(solr_doc['other_identifier_sim']).to include('12345678','8675309 testing')
      expect(solr_doc['other_identifier_sim']).not_to include('123456788675309 testing')
    end
    it 'should index identifier for master files' do
      master_file = FactoryBot.create(:master_file, identifier: ['TestOtherID'], media_object: media_object)
      media_object.reload
      solr_doc = media_object.to_solr(include_child_fields: true)
      expect(solr_doc['other_identifier_sim']).to include('TestOtherID')
    end
    it 'should index labels for master files' do
      FactoryBot.create(:master_file, :with_structure, media_object: media_object, title: 'Test Label')
      media_object.reload
      solr_doc = media_object.to_solr(include_child_fields: true)
      expect(solr_doc['section_label_tesim']).to include('CD 1')
      expect(solr_doc['section_label_tesim']).to include('Test Label')
    end
    it 'should index comments for master files' do
      FactoryBot.create(:master_file, media_object: media_object, title: 'Test Label', comment: ['MF Comment 1', 'MF Comment 2'])
      media_object.comment = ['MO Comment']
      media_object.save!
      media_object.reload
      solr_doc = media_object.to_solr(include_child_fields: true)
      expect(solr_doc['all_comments_sim']).to include('MO Comment')
      expect(solr_doc['all_comments_sim']).to include('[Test Label] MF Comment 1')
      expect(solr_doc['all_comments_sim']).to include('[Test Label] MF Comment 2')
    end
    it 'includes virtual group leases in external group facet' do
      media_object.governing_policies += [FactoryBot.create(:lease, inherited_read_groups: ['TestGroup'])]
      media_object.save!
      expect(media_object.to_solr['read_access_virtual_group_ssim']).to include('TestGroup')
    end
    it 'includes ip group leases in ip group facet' do
      ip_addr = Faker::Internet.ip_v4_address
      media_object.governing_policies += [FactoryBot.create(:lease, inherited_read_groups: [ip_addr])]
      media_object.save!
      expect(media_object.to_solr['read_access_ip_group_ssim']).to include(ip_addr)
    end
  end

  describe 'permalink' do

    let(:media_object){ FactoryBot.create(:media_object) }

    before(:each) {
      Permalink.on_generate{ |obj,target| 'http://www.example.com/perma-url' }
    }

    after(:each) do
      Permalink.on_generate { nil }
    end

    context 'unpublished' do
      it 'is empty when unpublished' do
        expect(media_object.permalink).to be_blank
      end
    end

    context 'published' do

      before(:each){ media_object.publish!('C.S. Lewis') } # saves the object

      it 'responds to permalink' do
        expect(media_object.respond_to?(:permalink)).to be true
      end

      it 'sets the permalink on the object' do
        expect(media_object.permalink).not_to be_nil
      end

      it 'sets the correct permalink' do
        expect(media_object.permalink).to eq('http://www.example.com/perma-url')
      end

      it 'does not remove the permalink if the permalink service returns nil' do
        Permalink.on_generate{ nil }
        media_object.save
        expect(media_object.permalink).to eq('http://www.example.com/perma-url')
      end

    end

    context 'correct target' do

      it 'should link to the correct target' do
        media_object.save
        t = nil
        Permalink.on_generate { |obj, target|
          t = target
          'http://www.example.com/perma-url'
        }
        media_object.ensure_permalink!
        # TODO: Fix next line so that it uses Rails.application.routes.default_url_options
        expect(t).to eq("http://test.host/media_objects/#{CGI::escape(media_object.id)}")
        expect(media_object.permalink).to eq('http://www.example.com/perma-url')
      end

    end

    context 'error handling' do

      it 'logs an error when the permalink service returns an exception' do
        Permalink.on_generate{ 1 / 0 }
        expect(Rails.logger).to receive(:error).at_least(:once)
        media_object.ensure_permalink!
      end

    end

    describe "#ensure_permalink!" do
      it 'is not called when the object is not persisted' do
        expect(media_object).not_to receive(:ensure_permalink!)
        media_object.save
      end
    end


    describe '#ensure_permalink!' do
      it 'returns true when updated' do
        expect(media_object).to receive(:ensure_permalink!).at_least(1).times.and_return(false)
        media_object.publish!('C.S. Lewis')
      end

      it 'returns false when not updated' do
        media_object.publish!('C.S. Lewis')
        expect(media_object).to receive(:ensure_permalink!).and_return(false)
        media_object.save
      end
    end
  end

  describe 'bib import' do
    let(:bib_id) { '7763100' }
    let(:mods) { File.read(File.expand_path("../../fixtures/#{bib_id}.mods",__FILE__)) }
    describe 'only overrides correct fields' do
      before do
        media_object.resource_type = "moving image"
        media_object.format = "video/mpeg"
        instance = double("instance")
        allow(Avalon::BibRetriever).to receive(:for).and_return(instance)
        allow(instance).to receive(:get_record).and_return(mods)
      end

      it 'should not override format' do
        expect { media_object.descMetadata.populate_from_catalog!(bib_id, 'local') }.to_not change { media_object.format }
      end
      it 'should not override resource_type' do
        expect { media_object.descMetadata.populate_from_catalog!(bib_id, 'local') }.to_not change { media_object.resource_type }
      end
      it 'should override the title' do
        expect { media_object.descMetadata.populate_from_catalog!(bib_id, 'local') }.to change { media_object.title }.to "245 A : B F G K N P S"
      end
    end
    describe 'should strip whitespace from bib_id parameter' do
      let(:sru_url) { "http://zgate.example.edu:9000/db?version=1.1&operation=searchRetrieve&maximumRecords=1&recordSchema=marcxml&query=rec.id=#{bib_id}" }
      let(:sru_response) { File.read(File.expand_path("../../fixtures/#{bib_id}.xml",__FILE__)) }
      let!(:request) { stub_request(:get, sru_url).to_return(body: sru_response) }

      it 'should strip whitespace off bib_id parameter' do
        expect { media_object.descMetadata.populate_from_catalog!(" #{bib_id} ", 'local') }.to change { media_object.title }.to "245 A : B F G K N P S"
        expect(request).to have_been_requested
      end
    end
    describe 'nil date_issued fromm bib_import' do
      let(:sru_url) { "http://zgate.example.edu:9000/db?version=1.1&operation=searchRetrieve&maximumRecords=1&recordSchema=marcxml&query=rec.id=#{bib_id}" }
      let(:sru_response) { File.read(File.expand_path("../../fixtures/#{bib_id}-unknown.xml",__FILE__)) }
      let!(:request) { stub_request(:get, sru_url).to_return(body: sru_response) }
      it 'should not replace the previous value if there is one' do
        expect { media_object.descMetadata.populate_from_catalog!(" #{bib_id} ", 'local') }.to_not change { media_object.date_issued }
        expect(request).to have_been_requested
      end
      it 'should replace missing value with unknown/unknown' do
        media_object.date_issued = ''
        expect { media_object.descMetadata.populate_from_catalog!(" #{bib_id} ", 'local') }.to change { media_object.date_issued }.to 'unknown/unknown'
        expect(request).to have_been_requested
      end
    end

  end

  describe '#section_labels' do
    before do
      mf = FactoryBot.create(:master_file, :with_structure, title: 'Test Label', media_object: media_object)
      media_object.reload
    end
    it 'should return correct list of labels' do
      expect(media_object.section_labels.first).to eq 'CD 1'
      expect(media_object.section_labels).to include 'Test Label'
    end
  end

  describe '#physical_description' do
    it 'should return a list of physical descriptions' do
      mf = FactoryBot.create(:master_file, title: 'Test Label', physical_description: 'stone tablet', media_object: media_object)
      media_object.reload
      expect(media_object.section_physical_descriptions).to match(['stone tablet'])
    end

    it 'should not return nil physical descriptions' do
      mf = FactoryBot.create(:master_file, title: 'Test Label', media_object: media_object)
      media_object.reload
      expect(media_object.section_physical_descriptions).to match([])
    end

    it 'should return a unique list of physical descriptions' do
      mf = FactoryBot.create(:master_file, title: 'Test Label', physical_description: 'cave paintings', media_object: media_object)
      mf2 = FactoryBot.create(:master_file, title: 'Test Label2', physical_description: 'cave paintings', media_object: media_object)
      media_object.reload

      #expect(media_object.ordered_master_files.size).to eq(2)
      expect(media_object.section_physical_descriptions).to match(['cave paintings'])
    end
  end

  describe '#collection=' do
    let(:new_media_object) { MediaObject.new }
    let(:collection) { FactoryBot.create(:collection, default_hidden: true, default_read_users: ['archivist1@example.com'], default_read_groups: ['TestGroup', 'public'], default_lending_period: 86400)}

    it 'sets hidden based upon collection for new media objects' do
      expect {new_media_object.collection = collection}.to change {new_media_object.hidden?}.to(true).from(false)
    end
    it 'sets visibility based upon collection for new media objects' do
      expect {new_media_object.collection = collection}.to change {new_media_object.visibility}.to('public').from('private')
    end
    it 'sets read_users based upon collection for new media objects' do
      expect {new_media_object.collection = collection}.to change {new_media_object.read_users}.to(['archivist1@example.com']).from([])
    end
    it 'sets read_groups based upon collection for new media objects' do
      expect(new_media_object.read_groups).not_to include "TestGroup"
      expect {new_media_object.collection = collection}.to change {new_media_object.read_groups}.to include 'TestGroup'
    end
    it 'sets lending_period based upon collection for new media objects' do
      expect {new_media_object.collection = collection}.to change {new_media_object.lending_period}.to(86400).from(nil)
    end
    it 'does not change access control fields if not new media object' do
      expect {media_object.collection = collection}.not_to change {new_media_object.hidden?}
      expect {media_object.collection = collection}.not_to change {new_media_object.visibility}
      expect {media_object.collection = collection}.not_to change {new_media_object.read_users}
      expect {media_object.collection = collection}.not_to change {new_media_object.read_users}
      expect {media_object.collection = collection}.not_to change {new_media_object.lending_period}
    end
  end

  describe 'descMetadata' do
    it 'sets original_name to default value' do
      expect(media_object.descMetadata.original_name).to eq 'descMetadata.xml'
    end
    it 'is a valid MODS document' do
      media_object = FactoryBot.create(:media_object, :with_master_file)
      xsd_path = File.join(Rails.root, 'spec', 'fixtures', 'mods-3-6.xsd')
      # Note: we instantiate Schema with a file handle so that relative paths
      # to included schema definitions can be resolved
      File.open(xsd_path) do |f|
        xsd = Nokogiri::XML::Schema(f)
        expect(xsd.valid?(media_object.descMetadata.ng_xml)).to be_truthy
      end
    end
  end

  describe 'workflow' do
    it 'sets original_name to default value' do
      expect(media_object.workflow.original_name).to eq 'workflow.xml'
    end
  end

  describe '#related_item_url' do
    let(:media_object) { FactoryBot.build(:media_object) }
    let(:url) { 'http://example.com/' }

    before do
      media_object.descMetadata.content = <<~EOF
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd">
          <relatedItem displayLabel="Program">
            <location>
              <url>
                http://example.com/
              </url>
            </location>
          </relatedItem>
        </mods>
      EOF
    end

    it 'strips trailing new line characters' do
      expect(media_object.related_item_url.first[:url]).to eq url
    end
  end

  describe '#rights_statement' do
    let(:media_object) { FactoryBot.build(:media_object).tap {|mo| mo.workflow.last_completed_step = "resource-description"} }
    let(:rights_statement_uri) { ModsDocument::RIGHTS_STATEMENTS.keys.first }

    it 'has a rights_statement' do
      expect(media_object).to respond_to(:rights_statement)
      expect { media_object.rights_statement = rights_statement_uri }.to change { media_object.rights_statement }.from(nil).to(rights_statement_uri)
    end

    it 'is indexed' do
      media_object.rights_statement = rights_statement_uri
      expect(media_object.to_solr["rights_statement_ssi"]).to eq rights_statement_uri
    end

    it 'roundtrips' do
      media_object.rights_statement = rights_statement_uri
      media_object.save!
      expect(media_object.reload.rights_statement).to eq rights_statement_uri
    end

    context 'validation' do
      it 'returns true values in controlled vocabulary' do
        media_object.rights_statement = rights_statement_uri
        expect(media_object.valid?).to be_truthy
        expect(media_object.errors[:rights_statement]).to be_empty
      end

      it 'returns false and sets errors for values not in controlled vocabulary' do
        media_object.rights_statement = 'bad-value'
        expect(media_object.valid?).to be_falsey
        expect(media_object.errors[:rights_statement]).not_to be_empty
      end
    end
  end

  describe '#terms_of_use' do
    let(:media_object) { FactoryBot.build(:media_object).tap {|mo| mo.workflow.last_completed_step = "resource-description"} }
    let(:terms_of_use_value) { "Example terms of use" }

    it 'has a terms_of_use' do
      expect(media_object).to respond_to(:terms_of_use)
      expect { media_object.terms_of_use = terms_of_use_value }.to change { media_object.terms_of_use }.from(nil).to(terms_of_use_value)
    end

    it 'is indexed' do
      media_object.terms_of_use = terms_of_use_value
      expect(media_object.to_solr["terms_of_use_si"]).to eq terms_of_use_value
    end

    it 'roundtrips' do
      media_object.terms_of_use = terms_of_use_value
      media_object.save!
      expect(media_object.reload.terms_of_use).to eq terms_of_use_value
    end
  end

  describe '#to_ingest_api_hash' do
    context 'remove_identifiers parameter' do
      let(:media_object) { FactoryBot.build(:fully_searchable_media_object, identifier: ['ABCDE12345']) }

      it 'removes identifiers if parameter is true' do
        expect(media_object.identifier).not_to be_empty
        expect(media_object.to_ingest_api_hash(false, remove_identifiers: true)[:fields][:identifier]).to be_empty
      end

      it 'does not remove identifiers if parameter is not present' do
        expect(media_object.identifier).not_to be_empty
        expect(media_object.to_ingest_api_hash(false, remove_identifiers: false)[:fields][:identifier]).not_to be_empty
        expect(media_object.to_ingest_api_hash(false)[:fields][:identifier]).not_to be_empty
      end
    end

    context 'publish parameter' do
      let(:publisher) { 'admin@example.com' }
      let(:media_object) { FactoryBot.build(:fully_searchable_media_object, avalon_publisher: publisher) }

      it 'removes avalon_publisher when parameter is false' do
        expect(media_object).to be_published
        expect(media_object.to_ingest_api_hash(false, publish: false)[:fields][:avalon_publisher]).to be_blank
        expect(media_object.to_ingest_api_hash(false)[:fields][:avalon_publisher]).to be_blank
      end

      it 'does not remove avalon_publisher when parameter is true' do
        expect(media_object).to be_published
        expect(media_object.to_ingest_api_hash(false, publish: true)[:fields][:avalon_publisher]).to eq publisher
      end
    end
  end

  describe '#merge!' do
    let(:media_objects) { [] }

    before do
      2.times { media_objects << FactoryBot.create(:media_object, :with_master_file) }
    end

    context "no error" do
      it 'merges' do
        expect { media_object.merge! media_objects }.to change { media_object.master_files.to_a.count }.by(2)
        expect(media_objects.any? { |mo| MediaObject.exists?(mo.id) }).to be_falsey
      end
    end

    context "with error" do
      before do
        allow(media_objects.first).to receive(:destroy).and_return(false)
      end

      it 'merges partially' do
        successes, fails = media_object.merge! media_objects
        expect(successes).to eq([media_objects.second])
        expect(fails).to eq([media_objects.first])
        expect(media_objects.first.errors.count).to eq(1)

        expect(media_object.master_files.to_a.count).to eq(2)
        expect(MediaObject.exists?(media_objects.first.id)).to be_truthy
        expect(MediaObject.exists?(media_objects.second.id)).to be_falsey
      end
    end
  end

  describe '#access_text' do
    let(:media_object) { FactoryBot.create(:media_object) }

    context "public item" do
      before do
        media_object.visibility = "public"
      end

      it 'returns public text' do
        expect(media_object.access_text).to eq("This item is accessible by: the public.")
      end
    end

    context "restricted item" do
      before do
        media_object.visibility = "restricted"
      end

      it 'returns restricted text' do
        expect(media_object.access_text).to eq("This item is accessible by: logged-in users.")
      end
    end

    context "private item" do
      before do
        media_object.visibility = "private"
      end

      it 'returns private text' do
        expect(media_object.access_text).to eq("This item is accessible by: collection staff.")
      end
    end

    context "private item with leases" do
      before do
        media_object.visibility = "private"
        media_object.governing_policies += [FactoryBot.create(:lease, inherited_read_groups: ['TestGroup'])]
        media_object.governing_policies += [FactoryBot.create(:lease, inherited_read_groups: [Faker::Internet.ip_v4_address])]
      end

      it 'returns compound text' do
        expect(media_object.access_text).to eq("This item is accessible by: collection staff, users in specific groups, users in specific IP Ranges.")
      end
    end
  end

  it_behaves_like "an object that has supplemental files"

  describe 'lending_status' do
    it 'is available when no active checkouts' do
      expect(media_object.lending_status).to eq "available"
    end

    context 'with an active checkout' do
      before { FactoryBot.create(:checkout, media_object_id: media_object.id) }

      it 'is checked_out' do
        expect(media_object.lending_status).to eq "checked_out"
      end
    end
  end

  describe 'lending_period' do
    context 'there is not a custom lending period' do
      it 'sets the lending period to the system default' do
        expect(media_object.lending_period).to eq ActiveSupport::Duration.parse(Settings.controlled_digital_lending.default_lending_period).to_i
      end
    end
    context 'the parent collection has a custom lending period' do
      let(:collection) { FactoryBot.create(:collection, default_lending_period: 86400) }
      let(:media_object) { FactoryBot.create(:media_object, collection_id: collection.id) }
      it "sets the lending period to equal the collection's default lending period" do
        expect(media_object.lending_period).to eq collection.default_lending_period
      end
      context 'the media object has a custom lending period' do
        let(:media_object) { FactoryBot.create(:media_object, collection_id: collection.id, lending_period: 172800)}
        it "leaves the lending period equal to the custom value" do
          expect(media_object.lending_period).to eq 172800
        end
      end
    end
  end

  describe 'read_groups=' do
    let(:solr_doc) { ActiveFedora::SolrService.query("id:#{media_object.id}").first }

    context 'when creating a MediaObject' do
      let(:media_object) { FactoryBot.build(:media_object) }

      it 'saves and indexes' do
        expect(media_object.read_groups).to be_empty
        media_object.read_groups = ["ExternalGroup"]
        expect(media_object.access_control).to be_changed
        media_object.save
        expect(media_object.reload.read_groups).to eq ["ExternalGroup"]
        expect(solr_doc["read_access_group_ssim"]).to eq ["ExternalGroup"]
      end
    end

    context 'when updating a MediaObject' do
      let(:media_object) { FactoryBot.create(:media_object) }

      it 'saves and indexes' do
        expect(media_object.read_groups).to be_empty
        media_object.read_groups = ["ExternalGroup"]
        expect(media_object.access_control).to be_changed
        media_object.save
        expect(media_object.reload.read_groups).to eq ["ExternalGroup"]
        expect(solr_doc["read_access_group_ssim"]).to eq ["ExternalGroup"]
      end
    end
  end
end
