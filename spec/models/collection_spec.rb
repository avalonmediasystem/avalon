require 'spec_helper'
require 'cancan/matchers'

describe Collection do
  subject {collection}
  let(:collection) {FactoryGirl.create(:collection)}

  describe 'abilities' do

    context 'when administator' do
      subject{ ability }
      let(:ability){ Ability.new(user) }
      let(:user){ FactoryGirl.create(:administrator) }

      it{ should be_able_to(:manage, collection) }
    end

    context 'when manager' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ FactoryGirl.create(:manager) }
      
      it{ should be_able_to(:update, collection) }
      it{ should be_able_to(:read, collection) }
      it{ should_not be_able_to(:create, collection) }
      it{ should_not be_able_to(:destroy, collection) }
    end

    context 'when editor' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ FactoryGirl.create(:editor) }

      #Will need to define new action that covers just the things that an editor is allowed to edit
      it{ should be_able_to(:read, collection) }
      it{ should_not be_able_to(:create, collection) }
      it{ should_not be_able_to(:update, collection) }
      it{ should_not be_able_to(:destroy, collection) }
    end

    context 'when depositor' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ FactoryGirl.create(:depositor) }

      it{ should be_able_to(:read, collection) }
      it{ should_not be_able_to(:create, collection) }
      it{ should_not be_able_to(:update, collection) }
      it{ should_not be_able_to(:destroy, collection) }
    end
  end

  describe 'validations' do
    subject {wells_collection}
    let(:wells_collection) {FactoryGirl.create(:collection, name: 'Herman B. Wells Collection', unit: "University Archives", description: "Collection about our 11th university president, 1938-1962", managers: [manager], editors: [editor], depositors: [depositor])}
    let(:manager) {FactoryGirl.create(:manager)}
    let(:editor) {FactoryGirl.create(:editor)}
    let(:depositor) {FactoryGirl.create(:depositor)}
    let(:unit_names) {["University Archives", "Black Film Center/Archive"]}

    it {should validate_presence_of(:name)}
    it {should validate_uniqueness_of(:name)}
    it {should validate_presence_of(:unit)}
    it {should ensure_inclusion_of(:unit).in_array(unit_names)}

    its(:name) {should == "Herman B. Wells Collection"}
    its(:unit) {should == "University Archives"}
    its(:description) {should == "Collection about our 11th university president, 1938-1962"}
    its(:created_at) {should == DateTime.parse(wells_collection.create_date)}
    its(:managers) {should == [manager]}
    its(:editors) {should == [editor]}
    its(:depositors) {should == [depositor]}

    its(:rightsMetadata) {should be_kind_of Hydra::Datastream::RightsMetadata}
    its(:inheritedRights) {should be_kind_of Hydra::Datastream::InheritableRightsMetadata}
  end

  describe "#to_solr" do
    it "should solrize important information" do
     map = Solrizer::FieldMapper::Default.new
     collection.name = "Herman B. Wells Collection"
     collection.to_solr[ map.solr_name(:name, :string, :searchable).to_sym ].should == "Herman B. Wells Collection"
    end
  end

  describe "managers" do
    let!(:user) {FactoryGirl.create(:manager)}
    let!(:collection) {Collection.new}

    describe "#managers" do
      it "should return the intersection of edit_users and managers role" do
        collection.edit_users = [user.username, "pdinh"]
        RoleControls.should_receive("users").with("manager").and_return([user.username, "atomical"])
        collection.managers.should == [user]  #collection.edit_users & RoleControls.users("manager")
      end
    end
    describe "#managers=" do
      it "should add managers to the collection" do
        manager_list = [FactoryGirl.create(:manager), FactoryGirl.create(:manager)]
        collection.managers = manager_list
        collection.managers.should == manager_list
      end
      it "should call add_manager" do
        manager_list = [FactoryGirl.create(:manager), FactoryGirl.create(:manager)]
        collection.should_receive("add_manager").with(manager_list[0])
        collection.should_receive("add_manager").with(manager_list[1])
        collection.managers = manager_list
      end
      it "should remove managers from the collection" do
        collection.managers = [user]
        collection.managers.should == [user]
        collection.managers -= [user]
        collection.managers.should == []
      end
      it "should call remove_manager" do
        collection.managers = [user]
        collection.should_receive("remove_manager").with(user)
        collection.managers = [FactoryGirl.create(:manager)]
      end
    end
    describe "#add_manager" do
      it "should give edit access to the collection" do
        collection.add_manager(user)
        collection.edit_users.should include(user.username)
        collection.inherited_edit_users.should include(user.username)
        collection.managers.should include(user)
      end
      it "should not add users who do not have the manager role" do
        not_manager = FactoryGirl.create(:user)
        collection.add_manager(not_manager)
        collection.managers.should_not include(not_manager)
      end
    end
    describe "#remove_manager" do
      it "should revoke edit access to the collection" do
        collection.remove_manager(user)
        collection.edit_users.should_not include(user.username)
        collection.inherited_edit_users.should_not include(user.username)
        collection.managers.should_not include(user)
      end
      it "should not remove users who do not have the manager role" do
        not_manager = FactoryGirl.create(:user)
        collection.edit_users = [not_manager.username]
        collection.inherited_edit_users = [not_manager.username]
        collection.remove_manager(not_manager)
        collection.edit_users.should include(not_manager.username)
        collection.inherited_edit_users.should include(not_manager.username)
      end
    end
  end

  describe "editors" do
    let!(:user) {FactoryGirl.create(:editor)}
    let!(:collection) {Collection.new}

    describe "#editors" do
      it "should return the intersection of edit_users and editors role" do
        collection.edit_users = [user.username, "pdinh"]
        RoleControls.should_receive("users").with("editor").and_return([user.username, "atomical"])
        collection.editors.should == [user]  #collection.edit_users & RoleControls.users("editor")
      end
    end
    describe "#editors=" do
      it "should add editors to the collection" do
        editor_list = [FactoryGirl.create(:editor), FactoryGirl.create(:editor)]
        collection.editors = editor_list
        collection.editors.should == editor_list
      end
      it "should call add_editor" do
        editor_list = [FactoryGirl.create(:editor), FactoryGirl.create(:editor)]
        collection.should_receive("add_editor").with(editor_list[0])
        collection.should_receive("add_editor").with(editor_list[1])
        collection.editors = editor_list
      end
      it "should remove editors from the collection" do
        collection.editors = [user]
        collection.editors.should == [user]
        collection.editors -= [user]
        collection.editors.should == []
      end
      it "should call remove_editor" do
        collection.editors = [user]
        collection.should_receive("remove_editor").with(user)
        collection.editors = [FactoryGirl.create(:editor)]
      end
    end
    describe "#add_editor" do
      it "should give edit access to the collection and add to the editor role" do
        not_editor = FactoryGirl.create(:user)
        collection.add_editor(not_editor)
        collection.edit_users.should include(not_editor.username)
        collection.inherited_edit_users.should include(not_editor.username)
        collection.editors.should include(not_editor)
        RoleControls.users("editor").should include(not_editor.username)
      end
      it "should not try to add the user to the editor role if they already have it" do
        RoleControls.users("editor").should include(user.username)
        RoleControls.should_not_receive("add_user_role") 
        collection.add_editor(user)
      end
    end
    describe "#remove_editor" do
      it "should revoke edit access to the collection" do
        collection.add_editor(user)
        collection.remove_editor(user)
        collection.edit_users.should_not include(user.username)
        collection.inherited_edit_users.should_not include(user.username)
        collection.editors.should_not include(user)
      end
      it "should not remove users who do not have the editor role" do
        not_editor = FactoryGirl.create(:manager)
        collection.edit_users = [not_editor.username]
        collection.inherited_edit_users = [not_editor.username]
        collection.remove_editor(not_editor)
        collection.edit_users.should include(not_editor.username)
        collection.inherited_edit_users.should_not include(user.username)
      end
      it "should remove user from editor role if they no longer belong to a collection" do
        collection.remove_editor(user)
        RoleControls.users("editor").should_not include(user.username)
      end
      it "should not remove user from editor role if they still belong to collections" do
        c = FactoryGirl.create(:collection, editors: [user])
        collection.remove_editor(user)
        RoleControls.users("editor").should include(user.username)
      end
    end
  end

  describe "depositors" do
    let!(:user) {FactoryGirl.create(:depositor)}
    let!(:collection) {Collection.new}

    describe "#depositors" do
      it "should return the intersection of edit_users and depositors role" do
        collection.inherited_edit_users = [user.username, "pdinh"]
        RoleControls.should_receive("users").with("depositor").and_return([user.username, "atomical"])
        collection.depositors.should == [user]  #collection.edit_users & RoleControls.users("depositor")
      end
    end
    describe "#depositors=" do
      it "should add depositors to the collection" do
        depositor_list = [FactoryGirl.create(:depositor), FactoryGirl.create(:depositor)]
        collection.depositors = depositor_list
        collection.depositors.should == depositor_list
      end
      it "should call add_depositor" do
        depositor_list = [FactoryGirl.create(:depositor), FactoryGirl.create(:depositor)]
        collection.should_receive("add_depositor").with(depositor_list[0])
        collection.should_receive("add_depositor").with(depositor_list[1])
        collection.depositors = depositor_list
      end
      it "should remove depositors from the collection" do
        collection.depositors = [user]
        collection.depositors.should == [user]
        collection.depositors -= [user]
        collection.depositors.should == []
      end
      it "should call remove_depositor" do
        collection.add_depositor(user)
        collection.should_receive("remove_depositor").with(user)
        collection.depositors = [FactoryGirl.create(:depositor)]
      end
    end
    describe "#add_depositor" do
      it "should give edit access to the collection and add to the depositor role" do
        not_depositor = FactoryGirl.create(:user)
        collection.add_depositor(not_depositor)
        collection.inherited_edit_users.should include(not_depositor.username)
        collection.depositors.should include(not_depositor)
        RoleControls.users("depositor").should include(not_depositor.username)
      end
      it "should not try to add the user to the depositor role if they already have it" do
        RoleControls.users("depositor").should include(user.username)
        RoleControls.should_not_receive("add_user_role") 
        collection.add_depositor(user)
      end
    end
    describe "#remove_depositor" do
      it "should revoke edit access to the collection" do
        collection.add_depositor(user)
        collection.remove_depositor(user)
        collection.inherited_edit_users.should_not include(user.username)
        collection.depositors.should_not include(user)
      end
      it "should not remove users who do not have the depositor role" do
        not_depositor = FactoryGirl.create(:manager)
        collection.inherited_edit_users = [not_depositor.username]
        collection.remove_depositor(not_depositor)
        collection.inherited_edit_users.should include(not_depositor.username)
      end
      it "should remove user from depositor role if they no longer belong to a collection" do
        collection.remove_depositor(user)
        RoleControls.users("depositor").should_not include(user.username)
      end
      it "should not remove user from depositor role if they still belong to collections" do
        c = FactoryGirl.create(:collection, depositors: [user])
        collection.remove_depositor(user)
        RoleControls.users("depositor").should include(user.username)
      end
    end
  end

  describe "#inherited_edit_users" do
  end
  describe "#inherited_edit_users=" do
  end
end

