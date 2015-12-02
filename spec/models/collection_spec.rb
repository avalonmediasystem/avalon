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

describe Admin::Collection do
  subject {collection}
  let(:collection) {FactoryGirl.create(:collection)}

  describe 'abilities' do

    context 'when administrator' do
      subject{ ability }
      let(:ability){ Ability.new(user) }
      let(:user){ FactoryGirl.create(:administrator) }

      it{ is_expected.to be_able_to(:manage, collection) }
    end

    context 'when manager' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ User.where(username: collection.managers.first).first }
      
      it{ is_expected.to be_able_to(:read, Admin::Collection) }
      it{ is_expected.to be_able_to(:update, collection) }
      it{ is_expected.to be_able_to(:read, collection) }
      it{ is_expected.to be_able_to(:update_unit, collection) }
      it{ is_expected.to be_able_to(:update_managers, collection) }
      it{ is_expected.to be_able_to(:update_editors, collection) }
      it{ is_expected.to be_able_to(:update_depositors, collection) }
      it{ is_expected.to be_able_to(:create, Admin::Collection) }
      it{ is_expected.to be_able_to(:destroy, collection) }
      it{ is_expected.to be_able_to(:update_access_control, collection) }
    end

    context 'when editor' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ User.where(username: collection.editors.first).first }

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
      let(:user){ User.where(username: collection.depositors.first).first }

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
      let(:user){ FactoryGirl.create(:user) }

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
      let(:user){ FactoryGirl.create(:user_lti) }

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
    let(:wells_collection) {FactoryGirl.create(:collection, name: 'Herman B. Wells Collection', unit: "University Archives", description: "Collection about our 11th university president, 1938-1962", managers: [manager.username], editors: [editor.username], depositors: [depositor.username])}
    let(:manager) {FactoryGirl.create(:manager)}
    let(:editor) {FactoryGirl.create(:user)}
    let(:depositor) {FactoryGirl.create(:user)}

    it {is_expected.to validate_presence_of(:name)}
    it {is_expected.to validate_uniqueness_of(:name)}
    it "shouldn't complain about partial name matches" do
      FactoryGirl.create(:collection, name: "This little piggy went to market")
      expect { FactoryGirl.create(:collection, name: "This little piggy") }.not_to raise_error
    end
    it {is_expected.to validate_presence_of(:unit)}
    it {is_expected.to ensure_inclusion_of(:unit).in_array(Admin::Collection.units)}
    it "should ensure length of :managers is_at_least(1)"

    it "should have attributes" do
      expect(subject.name).to eq("Herman B. Wells Collection")
      expect(subject.unit).to eq("University Archives")
      expect(subject.description).to eq("Collection about our 11th university president, 1938-1962")
      expect(subject.created_at).to eq(DateTime.parse(wells_collection.create_date))
      expect(subject.managers).to eq([manager.username])
      expect(subject.editors).to eq([editor.username])
      expect(subject.depositors).to eq([depositor.username])
      expect(subject.rightsMetadata).to be_kind_of Hydra::Datastream::RightsMetadata
      expect(subject.inheritedRights).to be_kind_of Hydra::Datastream::InheritableRightsMetadata
      expect(subject.defaultRights).to be_kind_of Hydra::Datastream::NonIndexedRightsMetadata
    end
  end

  describe "Admin::Collection.units" do
    it "should return an array of units" do
      allow(Admin::Collection).to receive(:units).and_return ["University Archives", "Black Film Center/Archive"]
      expect(Admin::Collection.units).to be_an_instance_of Array
      expect(Admin::Collection.units).to eq(["University Archives", "Black Film Center/Archive"])
    end
  end

  describe "#to_solr" do
    it "should solrize important information" do
     map = Solrizer.default_field_mapper
     collection.name = "Herman B. Wells Collection"
     expect(collection.to_solr[ map.solr_name(:name, :stored_searchable, type: :string) ]).to eq("Herman B. Wells Collection")
    end
  end

  describe "managers" do
    let!(:user) {FactoryGirl.create(:manager)}
    let!(:collection) {Admin::Collection.new}

    describe "#managers" do
      it "should return the intersection of edit_users and managers role" do
        collection.edit_users = [user.username, "pdinh"]
        expect(RoleControls).to receive("users").with("manager").and_return([user.username, "atomical"])
        expect(RoleControls).to receive("users").with("administrator").and_return([])
        expect(collection.managers).to eq([user.username])  #collection.edit_users & RoleControls.users("manager")
      end
    end
    describe "#managers=" do
      it "should add managers to the collection" do
        manager_list = [FactoryGirl.create(:manager).username, FactoryGirl.create(:manager).username]
        collection.managers = manager_list
        expect(collection.managers).to eq(manager_list)
      end
      it "should call add_manager" do
        manager_list = [FactoryGirl.create(:manager).username, FactoryGirl.create(:manager).username]
        expect(collection).to receive("add_manager").with(manager_list[0])
        expect(collection).to receive("add_manager").with(manager_list[1])
        collection.managers = manager_list
      end
      it "should remove managers from the collection" do
        manager_list = [FactoryGirl.create(:manager).username, FactoryGirl.create(:manager).username]
        collection.managers = manager_list
        expect(collection.managers).to eq(manager_list)
        collection.managers -= manager_list
        expect(collection.managers).to eq([])
      end
      it "should call remove_manager" do
        collection.managers = [user.username]
        expect(collection).to receive("remove_manager").with(user.username)
        collection.managers = [FactoryGirl.create(:manager).username]
      end
    end
    describe "#add_manager" do
      it "should give edit access to the collection" do
        collection.add_manager(user.username)
        expect(collection.edit_users).to include(user.username)
        expect(collection.inherited_edit_users).to include(user.username)
        expect(collection.managers).to include(user.username)
      end
      it "should add users who have the administrator role" do
        administrator = FactoryGirl.create(:administrator)
        collection.add_manager(administrator.username)
        expect(collection.edit_users).to include(administrator.username)
        expect(collection.inherited_edit_users).to include(administrator.username)
        expect(collection.managers).to include(administrator.username)
      end
      it "should not add administrators to editors role" do
        administrator = FactoryGirl.create(:administrator)
        collection.add_manager(administrator.username)
        expect(collection.editors).not_to include(administrator.username)
      end
      it "should not add users who do not have the manager role" do
        not_manager = FactoryGirl.create(:user)
        expect {collection.add_manager(not_manager.username)}.to raise_error(ArgumentError)
        expect(collection.managers).not_to include(not_manager.username)
      end
    end
    describe "#remove_manager" do
      it "should revoke edit access to the collection" do
        collection.remove_manager(user.username)
        expect(collection.edit_users).not_to include(user.username)
        expect(collection.inherited_edit_users).not_to include(user.username)
        expect(collection.managers).not_to include(user.username)
      end
      it "should not remove users who do not have the manager role" do
        not_manager = FactoryGirl.create(:user)
        collection.edit_users = [not_manager.username]
        collection.inherited_edit_users = [not_manager.username]
        collection.remove_manager(not_manager.username)
        expect(collection.edit_users).to include(not_manager.username)
        expect(collection.inherited_edit_users).to include(not_manager.username)
      end
    end
  end

  describe "editors" do
    let!(:user) {FactoryGirl.create(:user)}
    let!(:collection) {Admin::Collection.new}

    describe "#editors" do
      it "should not return managers" do
        collection.edit_users = [user.username, FactoryGirl.create(:manager).username]
        expect(collection.editors).to eq([user.username])
      end
    end
    describe "#editors=" do
      it "should add editors to the collection" do
        editor_list = [FactoryGirl.create(:user).username, FactoryGirl.create(:user).username]
        collection.editors = editor_list
        expect(collection.editors).to eq(editor_list)
      end
      it "should call add_editor" do
        editor_list = [FactoryGirl.create(:user).username, FactoryGirl.create(:user).username]
        expect(collection).to receive("add_editor").with(editor_list[0])
        expect(collection).to receive("add_editor").with(editor_list[1])
        collection.editors = editor_list
      end
      it "should remove editors from the collection" do
        name = user.username
        collection.editors = [name]
        expect(collection.editors).to eq([name])
        collection.editors -= [name]
        expect(collection.editors).to eq([])
      end
      it "should call remove_editor" do
        collection.editors = [user.username]
        expect(collection).to receive("remove_editor").with(user.username)
        collection.editors = [FactoryGirl.create(:user).username]
      end
    end
    describe "#add_editor" do
      it "should give edit access to the collection" do
        not_editor = FactoryGirl.create(:user)
        collection.add_editor(not_editor.username)
        expect(collection.edit_users).to include(not_editor.username)
        expect(collection.inherited_edit_users).to include(not_editor.username)
        expect(collection.editors).to include(not_editor.username)
      end
    end
    describe "#remove_editor" do
      it "should revoke edit access to the collection" do
        collection.add_editor(user.username)
        collection.remove_editor(user.username)
        expect(collection.edit_users).not_to include(user.username)
        expect(collection.inherited_edit_users).not_to include(user.username)
        expect(collection.editors).not_to include(user.username)
      end
      it "should not remove users who do not have the editor role" do
        not_editor = FactoryGirl.create(:manager)
        collection.edit_users = [not_editor.username]
        collection.inherited_edit_users = [not_editor.username]
        collection.remove_editor(not_editor.username)
        expect(collection.edit_users).to include(not_editor.username)
        expect(collection.inherited_edit_users).not_to include(user.username)
      end
    end
  end

  describe "depositors" do
    let!(:user) {FactoryGirl.create(:user)}
    let!(:collection) {Admin::Collection.new}

    describe "#depositors" do
      it "should return the read_users" do
        collection.read_users = [user.username]
        expect(collection.depositors).to eq([user.username])
      end
    end
    describe "#depositors=" do
      it "should add depositors to the collection" do
        depositor_list = [FactoryGirl.create(:user).username, FactoryGirl.create(:user).username]
        collection.depositors = depositor_list
        expect(collection.depositors).to eq(depositor_list)
      end
      it "should call add_depositor" do
        depositor_list = [FactoryGirl.create(:user).username, FactoryGirl.create(:user).username]
        expect(collection).to receive("add_depositor").with(depositor_list[0])
        expect(collection).to receive("add_depositor").with(depositor_list[1])
        collection.depositors = depositor_list
      end
      it "should remove depositors from the collection" do
        name = user.username
        collection.depositors = [name]
        expect(collection.depositors).to eq([name])
        collection.depositors -= [name]
        expect(collection.depositors).to eq([])
      end
      it "should call remove_depositor" do
        collection.add_depositor(user.username)
        expect(collection).to receive("remove_depositor").with(user.username)
        collection.depositors = [FactoryGirl.create(:user).username]
      end
    end
    describe "#add_depositor" do
      it "should give edit access to the collection" do
        not_depositor = FactoryGirl.create(:user)
        collection.add_depositor(not_depositor.username)
        expect(collection.inherited_edit_users).to include(not_depositor.username)
        expect(collection.depositors).to include(not_depositor.username)
      end
    end
    describe "#remove_depositor" do
      it "should revoke edit access to the collection" do
        collection.add_depositor(user.username)
        collection.remove_depositor(user.username)
        expect(collection.inherited_edit_users).not_to include(user.username)
        expect(collection.depositors).not_to include(user.username)
      end
      it "should not remove users who do not have the depositor role" do
        not_depositor = FactoryGirl.create(:manager)
        collection.inherited_edit_users = [not_depositor.username]
        collection.remove_depositor(not_depositor.username)
        expect(collection.inherited_edit_users).to include(not_depositor.username)
      end
    end
  end

  describe "#inherited_edit_users" do
  end
  describe "#inherited_edit_users=" do
  end


  describe "#reassign_media_objects" do
    before do
      @media_objects = (1..3).map{ FactoryGirl.create(:media_object)}
      incomplete_object = MediaObject.new
      incomplete_object.save(validate: false)
      @media_objects << incomplete_object
      @source_collection = FactoryGirl.build(:collection, media_objects: @media_objects)
      @source_collection.save(:validate => false)
      @target_collection = FactoryGirl.create(:collection)
      Admin::Collection.reassign_media_objects(@media_objects, @source_collection, @target_collection)
    end

    it 'sets the new collection on media_object' do
      @media_objects.each{|m| expect(m.collection).to eql @target_collection }
    end

    it 'removes the media object from the source collection' do
      expect(@source_collection.media_objects).to eq []
    end

    it 'adds the media object to the target collection' do
      expect(@target_collection.media_objects).to eq @media_objects
    end
  end

  describe "default rights delegators" do
    let(:collection) {FactoryGirl.create(:collection)}

    describe "users" do
      let(:users) {(1..3).map {Faker::Internet.email}}

      before :each do
        collection.default_read_users = users
        collection.save
      end

      it "should persist assigned #default_read_users" do
        expect(Admin::Collection.find(collection.pid).default_read_users).to eq(users)
      end

      it "should persist empty #default_read_users" do
        collection.default_read_users = []
        collection.save
        expect(Admin::Collection.find(collection.pid).default_read_users).to eq([])
      end
    end

    describe "groups" do
      let(:groups) {(1..3).map {Faker::Lorem.sentence(4)}}

      before :each do
        collection.default_read_groups = groups
        collection.save
      end

      it "should persist assigned #default_read_groups" do
        expect(Admin::Collection.find(collection.pid).default_read_groups).to eq(groups)
      end

      it "should persist empty #default_read_groups" do
        collection.default_read_groups = []
        collection.save
        expect(Admin::Collection.find(collection.pid).default_read_groups).to eq([])
      end
    end
  end

  describe "callbacks" do
    describe "after_save reindex if name or unit has changed" do
      let!(:collection) {FactoryGirl.create(:collection)}
      it 'should call reindex_members if name has changed' do
        collection.name = "New name"
        expect(collection).to be_name_changed
        expect(collection).to receive("reindex_members").and_return(nil)
        collection.save
      end
      
      it 'should call reindex_members if unit has changed' do
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
      @collection = FactoryGirl.create(:collection, items: 3)
      allow(Admin::Collection).to receive(:find).with(@collection.pid).and_return(@collection)
    end
    it 'should reindex in the background' do
      expect(@collection.reindex_members {}).to be_a_kind_of(Delayed::Job)
    end
    it 'should call update_index on all member objects' do
      Delayed::Worker.delay_jobs = false
      @collection.media_objects.each {|mo| expect(mo).to receive("update_index").and_return(true)}
      @collection.reindex_members {}
      Delayed::Worker.delay_jobs = true
    end
  end

  describe '#create_dropbox_directory!' do
    let(:collection){ FactoryGirl.build(:collection) }

    it 'removes bad characters from collection name' do
      collection.name = '../../secret.rb'
      expect(Dir).to receive(:mkdir).with( File.join(Avalon::Configuration.lookup('dropbox.path'), '______secret_rb') )
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
      FileUtils.mkdir_p(File.join(Avalon::Configuration.lookup('dropbox.path'), 'african_art'))
      FileUtils.mkdir_p(File.join(Avalon::Configuration.lookup('dropbox.path'), 'african_art_2'))
      expect(Dir).to receive(:mkdir).with(File.join(Avalon::Configuration.lookup('dropbox.path'), 'african_art_3'))
      collection.send(:create_dropbox_directory!)
      FakeFS.deactivate!
    end
  end

  describe 'Unicode' do
    let(:collection_name) { "Collections & Favorites / \u6211\u7684\u6536\u85cf / \u03a4\u03b1 \u03b1\u03b3\u03b1\u03c0\u03b7\u03bc\u03ad\u03bd\u03b1 \u03bc\u03bf\u03c5" }
    let(:collection_dir)  { "Collections___Favorites___\u6211\u7684\u6536\u85cf___\u03a4\u03b1_\u03b1\u03b3\u03b1\u03c0\u03b7\u03bc\u03ad\u03bd\u03b1_\u03bc\u03bf\u03c5" }
    let(:collection)      { FactoryGirl.build(:collection) }

    it 'handles Unicode collection names correctly' do
      collection.name = collection_name
      expect(Dir).to receive(:mkdir).with( File.join(Avalon::Configuration.lookup('dropbox.path'), collection_dir) )
      allow(Dir).to receive(:mkdir)
      collection.send(:create_dropbox_directory!)
    end
  end
end
