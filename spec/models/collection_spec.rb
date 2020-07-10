# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

describe Admin::Collection do
  subject {collection}
  let(:collection) {FactoryBot.create(:collection)}

  describe 'abilities' do

    context 'when administrator' do
      subject{ ability }
      let(:ability){ Ability.new(user) }
      let(:user){ FactoryBot.create(:administrator) }

      it{ is_expected.to be_able_to(:manage, collection) }
    end

    context 'when manager' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ User.where(Devise.authentication_keys.first => collection.managers.first).first }

      it{ is_expected.to be_able_to(:create, Admin::Collection) }
      it{ is_expected.to be_able_to(:read, Admin::Collection) }
      it{ is_expected.to be_able_to(:update, collection) }
      it{ is_expected.to be_able_to(:read, collection) }
      it{ is_expected.to be_able_to(:update_unit, collection) }
      it{ is_expected.to be_able_to(:update_managers, collection) }
      it{ is_expected.to be_able_to(:update_editors, collection) }
      it{ is_expected.to be_able_to(:update_depositors, collection) }
      it{ is_expected.to be_able_to(:destroy, collection) }
      it{ is_expected.to be_able_to(:update_access_control, collection) }
    end

    context 'when editor' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ User.where(Devise.authentication_keys.first => collection.editors.first).first }

      #Will need to define new action that covers just the things that an editor is allowed to edit
      it{ is_expected.to be_able_to(:read, Admin::Collection) }
      it{ is_expected.to be_able_to(:read, collection) }
      it{ is_expected.to be_able_to(:update, collection) }
      it{ is_expected.not_to be_able_to(:update_unit, collection) }
      it{ is_expected.not_to be_able_to(:update_managers, collection) }
      it{ is_expected.not_to be_able_to(:update_editors, collection) }
      it{ is_expected.to be_able_to(:update_depositors, collection) }
      it{ is_expected.not_to be_able_to(:create, Admin::Collection) }
      it{ is_expected.not_to be_able_to(:destroy, collection) }
      it{ is_expected.not_to be_able_to(:update_access_control, collection) }
    end

    context 'when depositor' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ User.where(Devise.authentication_keys.first => collection.depositors.first).first }

      it{ is_expected.to be_able_to(:read, Admin::Collection) }
      it{ is_expected.to be_able_to(:read, collection) }
      it{ is_expected.not_to be_able_to(:update_unit, collection) }
      it{ is_expected.not_to be_able_to(:update_managers, collection) }
      it{ is_expected.not_to be_able_to(:update_editors, collection) }
      it{ is_expected.not_to be_able_to(:update_depositors, collection) }
      it{ is_expected.not_to be_able_to(:create, collection) }
      it{ is_expected.not_to be_able_to(:update, collection) }
      it{ is_expected.not_to be_able_to(:destroy, collection) }
      it{ is_expected.not_to be_able_to(:update_access_control, collection) }
    end

    context 'when end user' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ FactoryBot.create(:user) }

      it{ is_expected.not_to be_able_to(:read, Admin::Collection) }
      it{ is_expected.not_to be_able_to(:read, collection) }
      it{ is_expected.not_to be_able_to(:update_unit, collection) }
      it{ is_expected.not_to be_able_to(:update_managers, collection) }
      it{ is_expected.not_to be_able_to(:update_editors, collection) }
      it{ is_expected.not_to be_able_to(:update_depositors, collection) }
      it{ is_expected.not_to be_able_to(:create, collection) }
      it{ is_expected.not_to be_able_to(:update, collection) }
      it{ is_expected.not_to be_able_to(:destroy, collection) }
      it{ is_expected.not_to be_able_to(:update_access_control, collection) }
    end

    context 'when lti user' do
      subject { ability }
      let(:ability){ Ability.new(user) }
      let(:user){ FactoryBot.create(:user_lti) }

      it{ is_expected.not_to be_able_to(:read, Admin::Collection) }
      it{ is_expected.not_to be_able_to(:read, collection) }
      it{ is_expected.not_to be_able_to(:update_unit, collection) }
      it{ is_expected.not_to be_able_to(:update_managers, collection) }
      it{ is_expected.not_to be_able_to(:update_editors, collection) }
      it{ is_expected.not_to be_able_to(:update_depositors, collection) }
      it{ is_expected.not_to be_able_to(:create, collection) }
      it{ is_expected.not_to be_able_to(:update, collection) }
      it{ is_expected.not_to be_able_to(:destroy, collection) }
      it{ is_expected.not_to be_able_to(:update_access_control, collection) }
    end
  end

  describe 'validations' do
    subject {wells_collection}
    let(:wells_collection) do
      FactoryBot.create(:collection, name: 'Herman B. Wells Collection', unit: "Default Unit",
                        description: "Collection about our 11th university president, 1938-1962",
                        managers: [manager.user_key], editors: [editor.user_key], depositors: [depositor.user_key],
                        contact_email: contact_email, website_url: website_url, website_label: website_label)
    end
    let(:manager) {FactoryBot.create(:manager)}
    let(:editor) {FactoryBot.create(:user)}
    let(:depositor) {FactoryBot.create(:user)}
    let(:contact_email) { Faker::Internet.email }
    let(:website_label) { Faker::Lorem.words.join(' ') }
    let(:website_url) { Faker::Internet.url }

    it {is_expected.to validate_presence_of(:name)}
    context 'validate uniqueness of name' do
      before do
        subject
      end
      it "same name should be invalid" do
        expect { FactoryBot.create(:collection, name: 'Herman B. Wells Collection') }.to raise_error(ActiveFedora::RecordInvalid, 'Validation failed: Name is taken.')
      end
      it "same name with different case should be invalid" do
        expect { FactoryBot.create(:collection, name: 'herman b. wells COLLECTION') }.to raise_error(ActiveFedora::RecordInvalid, 'Validation failed: Name is taken.')
      end
      it "same name with whitespace changes should be invalid" do
        expect { FactoryBot.create(:collection, name: 'HermanB.WellsCollection') }.to raise_error(ActiveFedora::RecordInvalid, 'Validation failed: Name is taken.')
      end
      it "starts with same name should be valid" do
        expect(FactoryBot.build(:collection, name: 'Herman B. Wells Collection Highlights')).to be_valid
      end
    end
    it "shouldn't complain about partial name matches" do
      FactoryBot.create(:collection, name: "This little piggy went to market")
      expect { FactoryBot.create(:collection, name: "This little piggy") }.not_to raise_error
    end
    it {is_expected.to validate_presence_of(:unit)}
    it {is_expected.to validate_inclusion_of(:unit).in_array(Admin::Collection.units)}
    it { is_expected.to allow_value('collection@example.com').for(:contact_email) }
    it { is_expected.not_to allow_value('collection@').for(:contact_email) }
    it { is_expected.to allow_value('https://collection.example.com').for(:website_url) }
    it { is_expected.not_to allow_value('collection.example.com').for(:website_url) }
    it "should ensure length of :managers is_at_least(1)"

    it "should have attributes" do
      expect(subject.name).to eq("Herman B. Wells Collection")
      expect(subject.unit).to eq("Default Unit")
      expect(subject.description).to eq("Collection about our 11th university president, 1938-1962")
      expect(subject.created_at).to eq(wells_collection.create_date)
      expect(subject.managers).to eq([manager.user_key])
      expect(subject.editors).to eq([editor.user_key])
      expect(subject.depositors).to eq([depositor.user_key])
      expect(subject.contact_email).to eq(contact_email)
      expect(subject.website_label).to eq(website_label)
      expect(subject.website_url).to eq(website_url)
      # expect(subject.rightsMetadata).to be_kind_of Hydra::Datastream::RightsMetadata
      # expect(subject.inheritedRights).to be_kind_of Hydra::Datastream::InheritableRightsMetadata
      # expect(subject.defaultRights).to be_kind_of Hydra::Datastream::NonIndexedRightsMetadata
    end
  end

  describe "Admin::Collection.units" do
    it "should return an array of units" do
      allow(Avalon::ControlledVocabulary).to receive(:find_by_name).with(:units, sort: true).and_return ["Black Film Center/Archive", "University Archives"]
      expect(Admin::Collection.units).to be_an_instance_of Array
      expect(Admin::Collection.units).to eq(["Black Film Center/Archive", "University Archives"])
    end
  end

  describe "#to_solr" do
    it "should solrize important information" do
     collection.name = "Herman B. Wells Collection"
     expect(collection.to_solr[ "name_ssi" ]).to eq("Herman B. Wells Collection")
     expect(collection.to_solr[ "name_uniq_si" ]).to eq("hermanb.wellscollection")
     expect(collection.to_solr[ "has_poster_bsi" ]).to eq false
    end
  end

  describe "managers" do
    let!(:user) {FactoryBot.create(:manager)}
    let!(:collection) {Admin::Collection.new}

    describe "#managers" do
      it "should return the intersection of edit_users and managers role" do
        collection.edit_users = [user.user_key, "pdinh"]
        expect(Avalon::RoleControls).to receive("users").with("manager").and_return([user.user_key, "atomical"])
        expect(Avalon::RoleControls).to receive("users").with("administrator").and_return([])
        expect(collection.managers).to eq([user.user_key])  #collection.edit_users & RoleControls.users("manager")
      end
    end
    describe "#managers=" do
      it "should add managers to the collection" do
        manager_list = [FactoryBot.create(:manager).user_key, FactoryBot.create(:manager).user_key]
        collection.managers = manager_list
        expect(collection.managers).to eq(manager_list)
      end
      it "should call add_manager" do
        manager_list = [FactoryBot.create(:manager).user_key, FactoryBot.create(:manager).user_key]
        expect(collection).to receive("add_manager").with(manager_list[0])
        expect(collection).to receive("add_manager").with(manager_list[1])
        collection.managers = manager_list
      end
      it "should remove managers from the collection" do
        manager_list = [FactoryBot.create(:manager).user_key, FactoryBot.create(:manager).user_key]
        collection.managers = manager_list
        expect(collection.managers).to eq(manager_list)
        collection.managers -= [manager_list[1]]
        expect(collection.managers).to eq([manager_list[0]])
      end
      it "should call remove_manager" do
        collection.managers = [user.user_key]
        expect(collection).to receive("remove_manager").with(user.user_key)
        collection.managers = [FactoryBot.create(:manager).user_key]
      end
      it "should fail to remove only manager" do
        manager_list = [FactoryBot.create(:manager).user_key]
        collection.managers = manager_list
        expect(collection.managers).to eq(manager_list)
        expect{collection.managers=[]}.to raise_error(ArgumentError)
      end
    end
    describe "#add_manager" do
      it "should give edit access to the collection" do
        collection.add_manager(user.user_key)
        expect(collection.edit_users).to include(user.user_key)
        expect(collection.inherited_edit_users).to include(user.user_key)
        expect(collection.managers).to include(user.user_key)
      end
      it "should add users who have the administrator role" do
        administrator = FactoryBot.create(:administrator)
        collection.add_manager(administrator.user_key)
        expect(collection.edit_users).to include(administrator.user_key)
        expect(collection.inherited_edit_users).to include(administrator.user_key)
        expect(collection.managers).to include(administrator.user_key)
      end
      it "should not add administrators to editors role" do
        administrator = FactoryBot.create(:administrator)
        collection.add_manager(administrator.user_key)
        expect(collection.editors).not_to include(administrator.user_key)
      end
      it "should not add users who do not have the manager role" do
        not_manager = FactoryBot.create(:user)
        expect {collection.add_manager(not_manager.user_key)}.to raise_error(ArgumentError)
        expect(collection.managers).not_to include(not_manager.user_key)
      end
    end
    describe "#remove_manager" do
      it "should revoke edit access to the collection" do
        collection.remove_manager(user.user_key)
        expect(collection.edit_users).not_to include(user.user_key)
        expect(collection.inherited_edit_users).not_to include(user.user_key)
        expect(collection.managers).not_to include(user.user_key)
      end
      it "should not remove users who do not have the manager role" do
        not_manager = FactoryBot.create(:user)
        collection.edit_users = [not_manager.user_key]
        collection.inherited_edit_users = [not_manager.user_key]
        collection.remove_manager(not_manager.user_key)
        expect(collection.edit_users).to include(not_manager.user_key)
        expect(collection.inherited_edit_users).to include(not_manager.user_key)
      end
    end
  end
  describe "editors" do
    let!(:user) {FactoryBot.create(:user)}
    let!(:collection) {Admin::Collection.new}

    describe "#editors" do
      it "should not return managers" do
        collection.edit_users = [user.user_key, FactoryBot.create(:manager).user_key]
        expect(collection.editors).to eq([user.user_key])
      end
    end
    describe "#editors=" do
      it "should add editors to the collection" do
        editor_list = [FactoryBot.create(:user).user_key, FactoryBot.create(:user).user_key]
        collection.editors = editor_list
        expect(collection.editors).to eq(editor_list)
      end
      it "should call add_editor" do
        editor_list = [FactoryBot.create(:user).user_key, FactoryBot.create(:user).user_key]
        expect(collection).to receive("add_editor").with(editor_list[0])
        expect(collection).to receive("add_editor").with(editor_list[1])
        collection.editors = editor_list
      end
      it "should remove editors from the collection" do
        name = user.user_key
        collection.editors = [name]
        expect(collection.editors).to eq([name])
        collection.editors -= [name]
        expect(collection.editors).to eq([])
      end
      it "should call remove_editor" do
        collection.editors = [user.user_key]
        expect(collection).to receive("remove_editor").with(user.user_key)
        collection.editors = [FactoryBot.create(:user).user_key]
      end
    end
    describe "#add_editor" do
      it "should give edit access to the collection" do
        not_editor = FactoryBot.create(:user)
        collection.add_editor(not_editor.user_key)
        expect(collection.edit_users).to include(not_editor.user_key)
        expect(collection.inherited_edit_users).to include(not_editor.user_key)
        expect(collection.editors).to include(not_editor.user_key)
      end
    end
    describe "#remove_editor" do
      it "should revoke edit access to the collection" do
        collection.add_editor(user.user_key)
        collection.remove_editor(user.user_key)
        expect(collection.edit_users).not_to include(user.user_key)
        expect(collection.inherited_edit_users).not_to include(user.user_key)
        expect(collection.editors).not_to include(user.user_key)
      end
      it "should not remove users who do not have the editor role" do
        not_editor = FactoryBot.create(:manager)
        collection.edit_users = [not_editor.user_key]
        collection.inherited_edit_users = [not_editor.user_key]
        collection.remove_editor(not_editor.user_key)
        expect(collection.edit_users).to include(not_editor.user_key)
        expect(collection.inherited_edit_users).not_to include(user.user_key)
      end
    end
  end

  describe "depositors" do
    let!(:user) {FactoryBot.create(:user)}
    let!(:collection) {Admin::Collection.new}

    describe "#depositors" do
      it "should return the read_users" do
        collection.read_users = [user.user_key]
        expect(collection.depositors).to eq([user.user_key])
      end
    end
    describe "#depositors=" do
      it "should add depositors to the collection" do
        depositor_list = [FactoryBot.create(:user).user_key, FactoryBot.create(:user).user_key]
        collection.depositors = depositor_list
        expect(collection.depositors).to eq(depositor_list)
      end
      it "should call add_depositor" do
        depositor_list = [FactoryBot.create(:user).user_key, FactoryBot.create(:user).user_key]
        expect(collection).to receive("add_depositor").with(depositor_list[0])
        expect(collection).to receive("add_depositor").with(depositor_list[1])
        collection.depositors = depositor_list
      end
      it "should remove depositors from the collection" do
        name = user.user_key
        collection.depositors = [name]
        expect(collection.depositors).to eq([name])
        collection.depositors -= [name]
        expect(collection.depositors).to eq([])
      end
      it "should call remove_depositor" do
        collection.add_depositor(user.user_key)
        expect(collection).to receive("remove_depositor").with(user.user_key)
        collection.depositors = [FactoryBot.create(:user).user_key]
      end
    end
    describe "#add_depositor" do
      it "should give edit access to the collection" do
        not_depositor = FactoryBot.create(:user)
        collection.add_depositor(not_depositor.user_key)
        expect(collection.inherited_edit_users).to include(not_depositor.user_key)
        expect(collection.depositors).to include(not_depositor.user_key)
      end
    end
    describe "#remove_depositor" do
      it "should revoke edit access to the collection" do
        collection.add_depositor(user.user_key)
        collection.remove_depositor(user.user_key)
        expect(collection.inherited_edit_users).not_to include(user.user_key)
        expect(collection.depositors).not_to include(user.user_key)
      end
      it "should not remove users who do not have the depositor role" do
        not_depositor = FactoryBot.create(:manager)
        collection.inherited_edit_users = [not_depositor.user_key]
        collection.remove_depositor(not_depositor.user_key)
        expect(collection.inherited_edit_users).to include(not_depositor.user_key)
      end
    end
  end

  describe "#inherited_edit_users" do
  end
  describe "#inherited_edit_users=" do
  end


  describe "#reassign_media_objects" do
    before do
      @source_collection = FactoryBot.create(:collection)
      @media_objects = (1..3).map{ FactoryBot.build(:media_object, collection: @source_collection)}
      # TODO: Fix handling of invalid objects
      # incomplete_object = MediaObject.new(collection: @source_collection)
      # @media_objects << incomplete_object
      @media_objects.map { |mo| mo.save }
      @target_collection = FactoryBot.create(:collection)
      Admin::Collection.reassign_media_objects(@media_objects, @source_collection, @target_collection)
    end

    it 'sets the new collection on media_object' do
      @media_objects.each{|m| expect(m.collection).to eql @target_collection }
    end

    it 'removes the media object from the source collection' do
      expect(@source_collection.media_objects).to eq []
    end

    it 'adds the media object to the target collection' do
      expect(@target_collection.media_objects).to match_array @media_objects
    end
  end

  describe "default rights delegators" do
    let(:collection) {FactoryBot.create(:collection)}

    describe "users" do
      let(:users) {(1..3).map {Faker::Internet.email}}

      before :each do
        collection.default_read_users = users
        collection.save
      end

      it "should persist assigned #default_read_users" do
        expect(Admin::Collection.find(collection.id).default_read_users).to eq(users)
      end

      it "should persist empty #default_read_users" do
        collection.default_read_users = []
        collection.save
        expect(Admin::Collection.find(collection.id).default_read_users).to eq([])
      end
    end

    describe "groups" do
      let(:groups) {(1..3).map {Faker::Lorem.sentence(4)}}

      before :each do
        collection.default_read_groups = groups
        collection.save
      end

      it "should persist assigned #default_read_groups" do
        expect(Admin::Collection.find(collection.id).default_read_groups).to eq(groups)
      end

      it "should persist empty #default_read_groups" do
        collection.default_read_groups = []
        collection.save
        expect(Admin::Collection.find(collection.id).default_read_groups).to eq([])
      end
    end

    describe 'visiblity' do
      it 'should default to private' do
        expect(collection.default_visibility).to eq 'private'
      end
      it 'should not override on create' do
        c = FactoryBot.create(:collection, default_visibility: 'public')
        expect(c.default_visibility).to eq 'public'
      end
    end
  end

  describe "callbacks" do
    describe "after_save reindex if name or unit has changed" do
      let!(:collection) {FactoryBot.create(:collection)}
      it 'should call reindex_members if name has changed' do
        collection.name = "New name"
        expect(collection).to be_name_changed
        expect(collection).to receive("reindex_members").and_return(nil)
        collection.save
      end

      it 'should call reindex_members if unit has changed' do
        allow(Admin::Collection).to receive(:units).and_return ["Default Unit", "Some Other Unit"]
        collection.unit = Admin::Collection.units.last
        expect(collection).to be_unit_changed
        expect(collection).to receive("reindex_members").and_return(nil)
        collection.save
      end

      it 'should not call reindex_members if name or unit has not been changed' do
        collection.description = "A different description"
        expect(collection).not_to be_name_changed
        expect(collection).not_to be_unit_changed
        expect(collection).not_to receive("reindex_members")
        collection.save
      end
    end
  end

  describe "reindex_members" do
    before do
      @collection = FactoryBot.create(:collection, items: 3)
    end
    it 'should queue a reindex job for all member objects' do
      @collection.reindex_members {}
      expect(ReindexJob).to have_been_enqueued.with(@collection.media_object_ids)
    end
  end

  describe '#create_dropbox_directory!' do
    let(:collection){ FactoryBot.build(:collection) }

    it 'removes bad characters from collection name' do
      collection.name = '../../secret.rb'
      expect(Dir).to receive(:mkdir).with( File.join(Settings.dropbox.path, '______secret_rb') )
      allow(Dir).to receive(:mkdir) # stubbing this out in a before(:each) block will effect where mkdir is used elsewhere (i.e. factories)
      collection.send(:create_dropbox_directory!)
    end
    it 'sets dropbox_directory_name on collection' do
      collection.name = 'african art'
      allow(Dir).to receive(:mkdir)
      collection.send(:create_dropbox_directory!)
      expect(collection.dropbox_directory_name).to eq('african_art')
    end
    it 'uses a different directory name if the directory exists' do
      collection.name = 'african art'
      FakeFS.activate!
      FileUtils.mkdir_p(File.join(Settings.dropbox.path, 'african_art'))
      FileUtils.mkdir_p(File.join(Settings.dropbox.path, 'african_art_2'))
      expect(Dir).to receive(:mkdir).with(File.join(Settings.dropbox.path, 'african_art_3'))
      collection.send(:create_dropbox_directory!)
      FakeFS.deactivate!
    end
  end

  describe '#destroy_dropbox_directory!' do
    let(:collection){ FactoryBot.build(:collection)}

    it 'deletes collection\'s dropbox directory' do
      collection.name = 'black history'
      collection.send(:destroy_dropbox_directory!)
      expect(File.directory?(File.join(Settings.dropbox.path, 'black_history'))).to be_falsey
    end
  end

  describe 'Unicode' do
    let(:collection_name) { "Collections & Favorites / \u6211\u7684\u6536\u85cf / \u03a4\u03b1 \u03b1\u03b3\u03b1\u03c0\u03b7\u03bc\u03ad\u03bd\u03b1 \u03bc\u03bf\u03c5" }
    let(:collection_dir)  { "Collections___Favorites___\u6211\u7684\u6536\u85cf___\u03a4\u03b1_\u03b1\u03b3\u03b1\u03c0\u03b7\u03bc\u03ad\u03bd\u03b1_\u03bc\u03bf\u03c5" }
    let(:collection)      { FactoryBot.build(:collection) }

    it 'handles Unicode collection names correctly' do
      collection.name = collection_name
      expect(Dir).to receive(:mkdir).with( File.join(Settings.dropbox.path, collection_dir) )
      allow(Dir).to receive(:mkdir)
      collection.send(:create_dropbox_directory!)
    end
  end

  describe 'create_s3_dropbox_directory!' do
    let(:bucket) { "mybucket" }
    let(:collection_name) { "Collection !@#$%^&*()[]{}123"}
    let(:corrected_collection_name) { "Collection__@_$___*()____123/" }
    let(:collection) { FactoryBot.build(:collection) }
    let(:my_client) { Aws::S3::Client.new }
    let!(:old_path) { Settings.dropbox.path }

    before do
      Settings.dropbox.path = "s3://#{bucket}/dropbox"
      Aws.config[:s3] = {
        stub_responses: {
          head_object: { status_code: 404, headers: {}, body: '', }
        }
      }
    end

    it "should be able to handle special S3 avoidable characters and create object" do      
      allow(Aws::S3::Client).to receive(:new).and_return(my_client)
      collection.name = collection_name
      expect(my_client).to receive(:put_object).with(bucket: bucket, key: corrected_collection_name)
      collection.send(:create_s3_dropbox_directory!)
    end

    after do
      Settings.dropbox.path = old_path
      Aws.config[:s3] = {
        stub_responses: {
          head_object: { status_code: 200, headers: {}, body: '', }
        }
      }
    end
  end
end
