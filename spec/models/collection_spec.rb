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

      it{ should be_able_to(:manage, collection) }
    end

    context 'when manager' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ User.where(username: collection.managers.first).first }
      
      it{ should be_able_to(:read, Admin::Collection) }
      it{ should be_able_to(:update, collection) }
      it{ should be_able_to(:read, collection) }
      it{ should be_able_to(:update_unit, collection) }
      it{ should be_able_to(:update_managers, collection) }
      it{ should be_able_to(:update_editors, collection) }
      it{ should be_able_to(:update_depositors, collection) }
      it{ should be_able_to(:create, Admin::Collection) }
      it{ should be_able_to(:destroy, collection) }
      it{ should be_able_to(:update_access_control, collection) }
    end

    context 'when editor' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ User.where(username: collection.editors.first).first }

      #Will need to define new action that covers just the things that an editor is allowed to edit
      it{ should be_able_to(:read, Admin::Collection) }
      it{ should be_able_to(:read, collection) }
      it{ should be_able_to(:update, collection) }
      it{ should_not be_able_to(:update_unit, collection) }
      it{ should_not be_able_to(:update_managers, collection) }
      it{ should_not be_able_to(:update_editors, collection) }
      it{ should be_able_to(:update_depositors, collection) }
      it{ should_not be_able_to(:create, Admin::Collection) }
      it{ should_not be_able_to(:destroy, collection) }
      it{ should_not be_able_to(:update_access_control, collection) }
    end

    context 'when depositor' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ User.where(username: collection.depositors.first).first }

      it{ should be_able_to(:read, Admin::Collection) }
      it{ should be_able_to(:read, collection) }
      it{ should_not be_able_to(:update_unit, collection) }
      it{ should_not be_able_to(:update_managers, collection) }
      it{ should_not be_able_to(:update_editors, collection) }
      it{ should_not be_able_to(:update_depositors, collection) }
      it{ should_not be_able_to(:create, collection) }
      it{ should_not be_able_to(:update, collection) }
      it{ should_not be_able_to(:destroy, collection) }
      it{ should_not be_able_to(:update_access_control, collection) }
    end

    context 'when end user' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ FactoryGirl.create(:user) }

      it{ should_not be_able_to(:read, Admin::Collection) }
      it{ should_not be_able_to(:read, collection) }
      it{ should_not be_able_to(:update_unit, collection) }
      it{ should_not be_able_to(:update_managers, collection) }
      it{ should_not be_able_to(:update_editors, collection) }
      it{ should_not be_able_to(:update_depositors, collection) }
      it{ should_not be_able_to(:create, collection) }
      it{ should_not be_able_to(:update, collection) }
      it{ should_not be_able_to(:destroy, collection) }
      it{ should_not be_able_to(:update_access_control, collection) }
    end

    context 'when lti user' do
      subject { ability }
      let(:ability){ Ability.new(user) }
      let(:user){ FactoryGirl.create(:user_lti) }

      it{ should_not be_able_to(:read, Admin::Collection) }
      it{ should_not be_able_to(:read, collection) }
      it{ should_not be_able_to(:update_unit, collection) }
      it{ should_not be_able_to(:update_managers, collection) }
      it{ should_not be_able_to(:update_editors, collection) }
      it{ should_not be_able_to(:update_depositors, collection) }
      it{ should_not be_able_to(:create, collection) }
      it{ should_not be_able_to(:update, collection) }
      it{ should_not be_able_to(:destroy, collection) }
      it{ should_not be_able_to(:update_access_control, collection) }
    end
  end

  describe 'validations' do
    subject {wells_collection}
    let(:wells_collection) {FactoryGirl.create(:collection, name: 'Herman B. Wells Collection', unit: "University Archives", description: "Collection about our 11th university president, 1938-1962", managers: [manager.username], editors: [editor.username], depositors: [depositor.username])}
    let(:manager) {FactoryGirl.create(:manager)}
    let(:editor) {FactoryGirl.create(:user)}
    let(:depositor) {FactoryGirl.create(:user)}

    it {should validate_presence_of(:name)}
    it {should validate_uniqueness_of(:name)}
    it "shouldn't complain about partial name matches" do
      FactoryGirl.create(:collection, name: "This little piggy went to market")
      expect { FactoryGirl.create(:collection, name: "This little piggy") }.not_to raise_error
    end
    it {should validate_presence_of(:unit)}
    it {should ensure_inclusion_of(:unit).in_array(Admin::Collection.units)}
    it "should ensure length of :managers is_at_least(1)"

    its(:name) {should == "Herman B. Wells Collection"}
    its(:unit) {should == "University Archives"}
    its(:description) {should == "Collection about our 11th university president, 1938-1962"}
    its(:created_at) {should == DateTime.parse(wells_collection.create_date)}
    its(:managers) {should == [manager.username]}
    its(:editors) {should == [editor.username]}
    its(:depositors) {should == [depositor.username]}

    its(:rightsMetadata) {should be_kind_of Hydra::Datastream::RightsMetadata}
    its(:inheritedRights) {should be_kind_of Hydra::Datastream::InheritableRightsMetadata}
    its(:defaultRights) {should be_kind_of Hydra::Datastream::NonIndexedRightsMetadata}
  end

  describe "Admin::Collection.units" do
    it "should return an array of units" do
      Admin::Collection.stub(:units).and_return ["University Archives", "Black Film Center/Archive"]
      Admin::Collection.units.should be_an_instance_of Array
      Admin::Collection.units.should == ["University Archives", "Black Film Center/Archive"]
    end
  end

  describe "#to_solr" do
    it "should solrize important information" do
     map = Solrizer.default_field_mapper
     collection.name = "Herman B. Wells Collection"
     collection.to_solr[ map.solr_name(:name, :stored_searchable, type: :string) ].should == "Herman B. Wells Collection"
    end
  end

  describe "managers" do
    let!(:user) {FactoryGirl.create(:manager)}
    let!(:collection) {Admin::Collection.new}

    describe "#managers" do
      it "should return the intersection of edit_users and managers role" do
        collection.edit_users = [user.username, "pdinh"]
        RoleControls.should_receive("users").with("manager").and_return([user.username, "atomical"])
        RoleControls.should_receive("users").with("administrator").and_return([])
        collection.managers.should == [user.username]  #collection.edit_users & RoleControls.users("manager")
      end
    end
    describe "#managers=" do
      it "should add managers to the collection" do
        manager_list = [FactoryGirl.create(:manager).username, FactoryGirl.create(:manager).username]
        collection.managers = manager_list
        collection.managers.should == manager_list
      end
      it "should call add_manager" do
        manager_list = [FactoryGirl.create(:manager).username, FactoryGirl.create(:manager).username]
        collection.should_receive("add_manager").with(manager_list[0])
        collection.should_receive("add_manager").with(manager_list[1])
        collection.managers = manager_list
      end
      it "should remove managers from the collection" do
        manager_list = [FactoryGirl.create(:manager).username, FactoryGirl.create(:manager).username]
        collection.managers = manager_list
        collection.managers.should == manager_list
        collection.managers -= manager_list
        collection.managers.should == []
      end
      it "should call remove_manager" do
        collection.managers = [user.username]
        collection.should_receive("remove_manager").with(user.username)
        collection.managers = [FactoryGirl.create(:manager).username]
      end
    end
    describe "#add_manager" do
      it "should give edit access to the collection" do
        collection.add_manager(user.username)
        collection.edit_users.should include(user.username)
        collection.inherited_edit_users.should include(user.username)
        collection.managers.should include(user.username)
      end
      it "should add users who have the administrator role" do
        administrator = FactoryGirl.create(:administrator)
        collection.add_manager(administrator.username)
        collection.edit_users.should include(administrator.username)
        collection.inherited_edit_users.should include(administrator.username)
        collection.managers.should include(administrator.username)
      end
      it "should not add administrators to editors role" do
        administrator = FactoryGirl.create(:administrator)
        collection.add_manager(administrator.username)
        collection.editors.should_not include(administrator.username)
      end
      it "should not add users who do not have the manager role" do
        not_manager = FactoryGirl.create(:user)
        expect {collection.add_manager(not_manager.username)}.to raise_error(ArgumentError)
        collection.managers.should_not include(not_manager.username)
      end
    end
    describe "#remove_manager" do
      it "should revoke edit access to the collection" do
        collection.remove_manager(user.username)
        collection.edit_users.should_not include(user.username)
        collection.inherited_edit_users.should_not include(user.username)
        collection.managers.should_not include(user.username)
      end
      it "should not remove users who do not have the manager role" do
        not_manager = FactoryGirl.create(:user)
        collection.edit_users = [not_manager.username]
        collection.inherited_edit_users = [not_manager.username]
        collection.remove_manager(not_manager.username)
        collection.edit_users.should include(not_manager.username)
        collection.inherited_edit_users.should include(not_manager.username)
      end
    end
  end

  describe "editors" do
    let!(:user) {FactoryGirl.create(:user)}
    let!(:collection) {Admin::Collection.new}

    describe "#editors" do
      it "should not return managers" do
        collection.edit_users = [user.username, FactoryGirl.create(:manager).username]
        collection.editors.should == [user.username]
      end
    end
    describe "#editors=" do
      it "should add editors to the collection" do
        editor_list = [FactoryGirl.create(:user).username, FactoryGirl.create(:user).username]
        collection.editors = editor_list
        collection.editors.should == editor_list
      end
      it "should call add_editor" do
        editor_list = [FactoryGirl.create(:user).username, FactoryGirl.create(:user).username]
        collection.should_receive("add_editor").with(editor_list[0])
        collection.should_receive("add_editor").with(editor_list[1])
        collection.editors = editor_list
      end
      it "should remove editors from the collection" do
        name = user.username
        collection.editors = [name]
        collection.editors.should == [name]
        collection.editors -= [name]
        collection.editors.should == []
      end
      it "should call remove_editor" do
        collection.editors = [user.username]
        collection.should_receive("remove_editor").with(user.username)
        collection.editors = [FactoryGirl.create(:user).username]
      end
    end
    describe "#add_editor" do
      it "should give edit access to the collection" do
        not_editor = FactoryGirl.create(:user)
        collection.add_editor(not_editor.username)
        collection.edit_users.should include(not_editor.username)
        collection.inherited_edit_users.should include(not_editor.username)
        collection.editors.should include(not_editor.username)
      end
    end
    describe "#remove_editor" do
      it "should revoke edit access to the collection" do
        collection.add_editor(user.username)
        collection.remove_editor(user.username)
        collection.edit_users.should_not include(user.username)
        collection.inherited_edit_users.should_not include(user.username)
        collection.editors.should_not include(user.username)
      end
      it "should not remove users who do not have the editor role" do
        not_editor = FactoryGirl.create(:manager)
        collection.edit_users = [not_editor.username]
        collection.inherited_edit_users = [not_editor.username]
        collection.remove_editor(not_editor.username)
        collection.edit_users.should include(not_editor.username)
        collection.inherited_edit_users.should_not include(user.username)
      end
    end
  end

  describe "depositors" do
    let!(:user) {FactoryGirl.create(:user)}
    let!(:collection) {Admin::Collection.new}

    describe "#depositors" do
      it "should return the read_users" do
        collection.read_users = [user.username]
        collection.depositors.should == [user.username]
      end
    end
    describe "#depositors=" do
      it "should add depositors to the collection" do
        depositor_list = [FactoryGirl.create(:user).username, FactoryGirl.create(:user).username]
        collection.depositors = depositor_list
        collection.depositors.should == depositor_list
      end
      it "should call add_depositor" do
        depositor_list = [FactoryGirl.create(:user).username, FactoryGirl.create(:user).username]
        collection.should_receive("add_depositor").with(depositor_list[0])
        collection.should_receive("add_depositor").with(depositor_list[1])
        collection.depositors = depositor_list
      end
      it "should remove depositors from the collection" do
        name = user.username
        collection.depositors = [name]
        collection.depositors.should == [name]
        collection.depositors -= [name]
        collection.depositors.should == []
      end
      it "should call remove_depositor" do
        collection.add_depositor(user.username)
        collection.should_receive("remove_depositor").with(user.username)
        collection.depositors = [FactoryGirl.create(:user).username]
      end
    end
    describe "#add_depositor" do
      it "should give edit access to the collection" do
        not_depositor = FactoryGirl.create(:user)
        collection.add_depositor(not_depositor.username)
        collection.inherited_edit_users.should include(not_depositor.username)
        collection.depositors.should include(not_depositor.username)
      end
    end
    describe "#remove_depositor" do
      it "should revoke edit access to the collection" do
        collection.add_depositor(user.username)
        collection.remove_depositor(user.username)
        collection.inherited_edit_users.should_not include(user.username)
        collection.depositors.should_not include(user.username)
      end
      it "should not remove users who do not have the depositor role" do
        not_depositor = FactoryGirl.create(:manager)
        collection.inherited_edit_users = [not_depositor.username]
        collection.remove_depositor(not_depositor.username)
        collection.inherited_edit_users.should include(not_depositor.username)
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
      @media_objects.each{|m| m.collection.should eql @target_collection }
    end

    it 'removes the media object from the source collection' do
      @source_collection.media_objects.should eq []
    end

    it 'adds the media object to the target collection' do
      @target_collection.media_objects.should eq @media_objects
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
        Admin::Collection.find(collection.pid).default_read_users.should == users
      end

      it "should persist empty #default_read_users" do
        collection.default_read_users = []
        collection.save
        Admin::Collection.find(collection.pid).default_read_users.should == []
      end
    end

    describe "groups" do
      let(:groups) {(1..3).map {Faker::Lorem.sentence(4)}}

      before :each do
        collection.default_read_groups = groups
        collection.save
      end

      it "should persist assigned #default_read_groups" do
        Admin::Collection.find(collection.pid).default_read_groups.should == groups
      end

      it "should persist empty #default_read_groups" do
        collection.default_read_groups = []
        collection.save
        Admin::Collection.find(collection.pid).default_read_groups.should == []
      end
    end
  end

  describe "callbacks" do
    describe "after_save reindex if name or unit has changed" do
      let!(:collection) {FactoryGirl.create(:collection)}
      it 'should call reindex_members if name has changed' do
        collection.name = "New name"
        collection.should be_name_changed
        collection.should_receive("reindex_members").and_return(nil)
        collection.save
      end
      
      it 'should call reindex_members if unit has changed' do
        collection.unit = Admin::Collection.units.last
        collection.should be_unit_changed
        collection.should_receive("reindex_members").and_return(nil)
        collection.save
      end

      it 'should not call reindex_members if name or unit has not been changed' do
        collection.description = "A different description"
        collection.should_not be_name_changed
        collection.should_not be_unit_changed
        collection.should_not_receive("reindex_members")
        collection.save
      end
    end
  end

  describe "reindex_members" do
    before do
      @media_objects = (1..3).map{ FactoryGirl.create(:media_object)}
      @collection = FactoryGirl.create(:collection, media_objects: @media_objects)
      allow(Admin::Collection).to receive(:find).with(@collection.pid).and_return(@collection)
    end
    it 'should reindex in the background' do
      expect(@collection.reindex_members {}).to be_a_kind_of(Delayed::Job)
    end
    it 'should call update_index on all member objects' do
      Delayed::Worker.delay_jobs = false
      @media_objects.each {|mo| mo.should_receive("update_index").and_return(true)}
      @collection.reindex_members {}
      Delayed::Worker.delay_jobs = true
    end
  end

  describe '#create_dropbox_directory!' do
    let(:collection){ FactoryGirl.build(:collection) }

    it 'removes bad characters from collection name' do
      collection.name = '../../secret.rb'
      Dir.should_receive(:mkdir).with( File.join(Avalon::Configuration.lookup('dropbox.path'), '______secret_rb') )
      Dir.stub(:mkdir) # stubbing this out in a before(:each) block will effect where mkdir is used elsewhere (i.e. factories)
      collection.send(:create_dropbox_directory!)
    end
    it 'sets dropbox_directory_name on collection' do
      collection.name = 'african art'
      Dir.stub(:mkdir)
      collection.send(:create_dropbox_directory!)
      collection.dropbox_directory_name.should == 'african_art'
    end
    it 'uses a different directory name if the directory exists' do
      collection.name = 'african art'
      FakeFS.activate!
      FileUtils.mkdir_p(File.join(Avalon::Configuration.lookup('dropbox.path'), 'african_art'))
      FileUtils.mkdir_p(File.join(Avalon::Configuration.lookup('dropbox.path'), 'african_art_2'))
      Dir.should_receive(:mkdir).with(File.join(Avalon::Configuration.lookup('dropbox.path'), 'african_art_3'))
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
      Dir.should_receive(:mkdir).with( File.join(Avalon::Configuration.lookup('dropbox.path'), collection_dir) )
      Dir.stub(:mkdir)
      collection.send(:create_dropbox_directory!)
    end
  end
end
