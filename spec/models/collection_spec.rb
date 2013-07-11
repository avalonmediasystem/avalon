require 'spec_helper'
require 'cancan/matchers'

describe Admin::Collection do
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
      let(:user){ User.where(username: collection.managers.first).first }
      
      it{ should be_able_to(:update, collection) }
      it{ should be_able_to(:read, collection) }
      it{ should be_able_to(:update_unit, collection) }
      it{ should be_able_to(:update_managers, collection) }
      it{ should be_able_to(:update_editors, collection) }
      it{ should be_able_to(:update_depositors, collection) }
      it{ should be_able_to(:create, Admin::Collection) }
    end

    context 'when editor' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ User.where(username: collection.editors.first).first }

      #Will need to define new action that covers just the things that an editor is allowed to edit
      it{ should be_able_to(:read, collection) }
      it{ should be_able_to(:update, collection) }
      it{ should_not be_able_to(:update_unit, collection) }
      it{ should_not be_able_to(:update_managers, collection) }
      it{ should_not be_able_to(:update_editors, collection) }
      it{ should be_able_to(:update_depositors, collection) }
      it{ should_not be_able_to(:create, Admin::Collection) }
      it{ should_not be_able_to(:destroy, collection) }
    end

    context 'when depositor' do
      subject{ ability}
      let(:ability){ Ability.new(user) }
      let(:user){ User.where(username: collection.depositors.first).first }

      it{ should be_able_to(:read, collection) }
      it{ should_not be_able_to(:update_unit, collection) }
      it{ should_not be_able_to(:update_managers, collection) }
      it{ should_not be_able_to(:update_editors, collection) }
      it{ should_not be_able_to(:update_depositors, collection) }
      it{ should_not be_able_to(:create, collection) }
      it{ should_not be_able_to(:update, collection) }
      it{ should_not be_able_to(:destroy, collection) }
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
    it {should validate_presence_of(:unit)}
    it {should ensure_inclusion_of(:unit).in_array(Admin::Collection.units)}

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
      Admin::Collection.units.should be_an_instance_of Array
      Admin::Collection.units.should == ["University Archives", "Black Film Center/Archive"]
    end
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
    let!(:collection) {Admin::Collection.new}

    describe "#managers" do
      it "should return the intersection of edit_users and managers role" do
        collection.edit_users = [user.username, "pdinh"]
        RoleControls.should_receive("users").with("manager").and_return([user.username, "atomical"])
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
        collection.managers = [user.username]
        collection.managers.should == [user.username]
        collection.managers -= [user.username]
        collection.managers.should == []
      end
      it "should call remove_manager" do
        collection.managers = [user.username]
        collection.should_receive("remove_manager").with(user.username)
        collection.managers = [FactoryGirl.create(:manager)]
      end
    end
    describe "#add_manager" do
      it "should give edit access to the collection" do
        collection.add_manager(user.username)
        collection.edit_users.should include(user.username)
        collection.inherited_edit_users.should include(user.username)
        collection.managers.should include(user.username)
      end
      it "should not add users who do not have the manager role" do
        not_manager = FactoryGirl.create(:user)
        collection.add_manager(not_manager.username)
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
        collection.editors = [user.username]
        collection.editors.should == [user.username]
        collection.editors -= [user.username]
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
        collection.depositors = [user.username]
        collection.depositors.should == [user.username]
        collection.depositors -= [user.username]
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
end

