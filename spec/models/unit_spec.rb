# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

describe Admin::Unit do
  subject { unit }
  let(:unit) { FactoryBot.create(:unit) }

  describe 'abilities' do
    context 'when administrator' do
      subject { ability }
      let(:ability) { Ability.new(user) }
      let(:user) { FactoryBot.create(:administrator) }

      it { is_expected.to be_able_to(:manage, unit) }
    end

    context 'when unit administrator' do
      subject { ability }
      let(:ability) { Ability.new(user) }
      let(:user) { User.where(Devise.authentication_keys.first => unit.unit_administrators.first).first }

      it { is_expected.to be_able_to(:create, Admin::Unit) }
      it { is_expected.to be_able_to(:read, Admin::Unit) }
      it { is_expected.to be_able_to(:update, unit) }
      it { is_expected.to be_able_to(:read, unit) }
      it { is_expected.to be_able_to(:update_unit_admins, unit) }
      it { is_expected.to be_able_to(:update_editors, unit) }
      it { is_expected.to be_able_to(:update_depositors, unit) }
      it { is_expected.to be_able_to(:destroy, unit) }
      it { is_expected.to be_able_to(:update_access_control, unit) }
    end

    context 'when editor' do
      subject { ability }
      let(:ability) { Ability.new(user) }
      let(:user) { User.where(Devise.authentication_keys.first => unit.editors.first).first }

      # Will need to define new action that covers just the things that an editor is allowed to edit
      it { is_expected.to be_able_to(:read, Admin::Unit) }
      it { is_expected.to be_able_to(:read, unit) }
      it { is_expected.to be_able_to(:update, unit) }
      it { is_expected.not_to be_able_to(:update_unit, unit) }
      it { is_expected.not_to be_able_to(:update_managers, unit) }
      it { is_expected.not_to be_able_to(:update_editors, unit) }
      it { is_expected.to be_able_to(:update_depositors, unit) }
      it { is_expected.not_to be_able_to(:create, Admin::Unit) }
      it { is_expected.not_to be_able_to(:destroy, unit) }
      it { is_expected.not_to be_able_to(:update_access_control, unit) }
    end

    context 'when depositor' do
      subject { ability }
      let(:ability) { Ability.new(user) }
      let(:user) { User.where(Devise.authentication_keys.first => unit.depositors.first).first }

      it { is_expected.to be_able_to(:read, Admin::Unit) }
      it { is_expected.to be_able_to(:read, unit) }
      it { is_expected.not_to be_able_to(:update_unit, unit) }
      it { is_expected.not_to be_able_to(:update_managers, unit) }
      it { is_expected.not_to be_able_to(:update_editors, unit) }
      it { is_expected.not_to be_able_to(:update_depositors, unit) }
      it { is_expected.not_to be_able_to(:create, unit) }
      it { is_expected.not_to be_able_to(:update, unit) }
      it { is_expected.not_to be_able_to(:destroy, unit) }
      it { is_expected.not_to be_able_to(:update_access_control, unit) }
    end

    context 'when end user' do
      subject { ability }
      let(:ability) { Ability.new(user) }
      let(:user) { FactoryBot.create(:user) }

      it { is_expected.not_to be_able_to(:read, Admin::Unit) }
      it { is_expected.not_to be_able_to(:read, unit) }
      it { is_expected.not_to be_able_to(:update_unit, unit) }
      it { is_expected.not_to be_able_to(:update_managers, unit) }
      it { is_expected.not_to be_able_to(:update_editors, unit) }
      it { is_expected.not_to be_able_to(:update_depositors, unit) }
      it { is_expected.not_to be_able_to(:create, unit) }
      it { is_expected.not_to be_able_to(:update, unit) }
      it { is_expected.not_to be_able_to(:destroy, unit) }
      it { is_expected.not_to be_able_to(:update_access_control, unit) }
    end

    context 'when lti user' do
      subject { ability }
      let(:ability) { Ability.new(user) }
      let(:user) { FactoryBot.create(:user_lti) }

      it { is_expected.not_to be_able_to(:read, Admin::Unit) }
      it { is_expected.not_to be_able_to(:read, unit) }
      it { is_expected.not_to be_able_to(:update_unit, unit) }
      it { is_expected.not_to be_able_to(:update_managers, unit) }
      it { is_expected.not_to be_able_to(:update_editors, unit) }
      it { is_expected.not_to be_able_to(:update_depositors, unit) }
      it { is_expected.not_to be_able_to(:create, unit) }
      it { is_expected.not_to be_able_to(:update, unit) }
      it { is_expected.not_to be_able_to(:destroy, unit) }
      it { is_expected.not_to be_able_to(:update_access_control, unit) }
    end
  end

  describe 'validations' do
    subject { wells_unit }
    let(:wells_unit) do
      FactoryBot.create(:unit,
                        name: 'Herman B. Wells unit',
                        description: "unit about our 11th university president, 1938-1962",
                        unit_admins: [unit_admin.user_key], editors: [editor.user_key], depositors: [depositor.user_key],
                        contact_email: contact_email, website_url: website_url, website_label: website_label)
    end
    let(:unit_admin) { FactoryBot.create(:unit_admin) }
    let(:editor) { FactoryBot.create(:user) }
    let(:depositor) { FactoryBot.create(:user) }
    let(:contact_email) { Faker::Internet.email }
    let(:website_label) { Faker::Lorem.words.join(' ') }
    let(:website_url) { Faker::Internet.url }

    it { is_expected.to validate_presence_of(:name) }
    context 'validate uniqueness of name' do
      before do
        subject
      end
      it "same name should be invalid" do
        expect { FactoryBot.create(:unit, name: 'Herman B. Wells unit') }.to raise_error(ActiveFedora::RecordInvalid, 'Validation failed: Name is taken.')
      end
      it "same name with different case should be invalid" do
        expect { FactoryBot.create(:unit, name: 'herman b. wells unit') }.to raise_error(ActiveFedora::RecordInvalid, 'Validation failed: Name is taken.')
      end
      it "same name with whitespace changes should be invalid" do
        expect { FactoryBot.create(:unit, name: 'HermanB.Wellsunit') }.to raise_error(ActiveFedora::RecordInvalid, 'Validation failed: Name is taken.')
      end
      it "starts with same name should be valid" do
        expect(FactoryBot.build(:unit, name: 'Herman B. Wells unit Highlights')).to be_valid
      end
    end
    it "shouldn't complain about partial name matches" do
      FactoryBot.create(:unit, name: "This little piggy went to market")
      expect { FactoryBot.create(:unit, name: "This little piggy") }.not_to raise_error
    end
    it { is_expected.to allow_value('unit@example.com').for(:contact_email) }
    it { is_expected.not_to allow_value('unit@').for(:contact_email) }
    it { is_expected.to allow_value('https://unit.example.com').for(:website_url) }
    it { is_expected.not_to allow_value('unit.example.com').for(:website_url) }

    it "should have attributes" do
      expect(subject.name).to eq("Herman B. Wells unit")
      expect(subject.description).to eq("unit about our 11th university president, 1938-1962")
      expect(subject.created_at).to eq(wells_unit.create_date)
      expect(subject.unit_admins).to eq([unit_admin.user_key])
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

  describe "#to_solr" do
    it "should solrize important information" do
      unit.name = "Herman B. Wells unit"
      expect(unit.to_solr["name_ssi"]).to eq("Herman B. Wells unit")
      expect(unit.to_solr["name_uniq_si"]).to eq("hermanb.wellsunit")
      expect(unit.to_solr["has_poster_bsi"]).to eq false
    end
  end

  describe "managers" do
    let!(:user) { FactoryBot.create(:manager) }
    let!(:unit) { Admin::Unit.new }

    describe "#managers" do
      it "should return the intersection of edit_users and unit_managers property" do
        unit.edit_users = [user.user_key, "pdinh"]
        unit.managers = [user.user_key]
        expect(unit.managers).to eq([user.user_key])
      end
    end
    describe "#managers=" do
      it "should add managers to the unit" do
        manager_list = [FactoryBot.create(:manager).user_key, FactoryBot.create(:manager).user_key]
        unit.managers = manager_list
        expect(unit.managers).to eq(manager_list)
      end
      it "should call add_manager" do
        manager_list = [FactoryBot.create(:manager).user_key, FactoryBot.create(:manager).user_key]
        expect(unit).to receive("add_manager").with(manager_list[0])
        expect(unit).to receive("add_manager").with(manager_list[1])
        unit.managers = manager_list
      end
      it "should remove managers from the unit" do
        manager_list = [FactoryBot.create(:manager).user_key, FactoryBot.create(:manager).user_key]
        unit.managers = manager_list
        expect(unit.managers).to eq(manager_list)
        unit.managers -= [manager_list[1]]
        expect(unit.managers).to eq([manager_list[0]])
      end
      it "should call remove_manager" do
        unit.managers = [user.user_key]
        expect(unit).to receive("remove_manager").with(user.user_key)
        unit.managers = [FactoryBot.create(:manager).user_key]
      end
      it "should fail to remove only manager" do
        manager_list = [FactoryBot.create(:manager).user_key]
        unit.managers = manager_list
        expect(unit.managers).to eq(manager_list)
        expect { unit.managers = [] }.to raise_error(ArgumentError)
      end
    end
    describe "#add_manager" do
      it "should give edit access to the unit" do
        unit.add_manager(user.user_key)
        expect(unit.edit_users).to include(user.user_key)
        expect(unit.inherited_edit_users).to include(user.user_key)
        expect(unit.managers).to include(user.user_key)
      end
      it "should add users who have the administrator role" do
        administrator = FactoryBot.create(:administrator)
        unit.add_manager(administrator.user_key)
        expect(unit.edit_users).to include(administrator.user_key)
        expect(unit.inherited_edit_users).to include(administrator.user_key)
        expect(unit.managers).to include(administrator.user_key)
      end
      it "should not add administrators to editors role" do
        administrator = FactoryBot.create(:administrator)
        unit.add_manager(administrator.user_key)
        expect(unit.editors).not_to include(administrator.user_key)
      end
      it "should not add users who do not have the manager role" do
        not_manager = FactoryBot.create(:user)
        expect { unit.add_manager(not_manager.user_key) }.to raise_error(ArgumentError)
        expect(unit.managers).not_to include(not_manager.user_key)
      end
    end
    describe "#remove_manager" do
      it "should revoke edit access to the unit" do
        unit.remove_manager(user.user_key)
        expect(unit.edit_users).not_to include(user.user_key)
        expect(unit.inherited_edit_users).not_to include(user.user_key)
        expect(unit.managers).not_to include(user.user_key)
      end
      it "should not remove users who do not have the manager role" do
        not_manager = FactoryBot.create(:user)
        unit.edit_users = [not_manager.user_key]
        unit.inherited_edit_users = [not_manager.user_key]
        unit.remove_manager(not_manager.user_key)
        expect(unit.edit_users).to include(not_manager.user_key)
        expect(unit.inherited_edit_users).to include(not_manager.user_key)
      end
    end
  end
  describe "editors" do
    let!(:user) { FactoryBot.create(:user) }
    let!(:unit) { Admin::Unit.new }

    describe "#editors" do
      it "should not return managers" do
        unit_admin = FactoryBot.create(:unit_admin)
        unit.edit_users = [user.user_key, unit_admin.user_key]
        unit.unit_administrators = [unit_admin.user_key]
        expect(unit.editors).to eq([user.user_key])
      end
    end
    describe "#editors=" do
      it "should add editors to the unit" do
        editor_list = [FactoryBot.create(:user).user_key, FactoryBot.create(:user).user_key]
        unit.editors = editor_list
        expect(unit.editors).to eq(editor_list)
      end
      it "should call add_editor" do
        editor_list = [FactoryBot.create(:user).user_key, FactoryBot.create(:user).user_key]
        expect(unit).to receive("add_editor").with(editor_list[0])
        expect(unit).to receive("add_editor").with(editor_list[1])
        unit.editors = editor_list
      end
      it "should remove editors from the unit" do
        name = user.user_key
        unit.editors = [name]
        expect(unit.editors).to eq([name])
        unit.editors -= [name]
        expect(unit.editors).to eq([])
      end
      it "should call remove_editor" do
        unit.editors = [user.user_key]
        expect(unit).to receive("remove_editor").with(user.user_key)
        unit.editors = [FactoryBot.create(:user).user_key]
      end
      # it "can add users who belong to manager group" do
      #   manager = FactoryBot.create(:manager)
      #   unit.editors = [manager.user_key]
      #   expect(unit.editors).to include(manager.user_key)
      #   expect(unit.managers).not_to include(manager.user_key)
      # end
      it "can add users who belong to administrator group" do
        admin = FactoryBot.create(:administrator)
        unit.editors = [admin.user_key]
        expect(unit.editors).to include(admin.user_key)
        expect(unit.unit_admins).not_to include(admin.user_key)
      end
    end
    describe "#add_editor" do
      it "should give edit access to the unit" do
        not_editor = FactoryBot.create(:user)
        unit.add_editor(not_editor.user_key)
        expect(unit.edit_users).to include(not_editor.user_key)
        expect(unit.inherited_edit_users).to include(not_editor.user_key)
        expect(unit.editors).to include(not_editor.user_key)
      end
    end
    describe "#remove_editor" do
      it "should revoke edit access to the unit" do
        unit.add_editor(user.user_key)
        unit.remove_editor(user.user_key)
        expect(unit.edit_users).not_to include(user.user_key)
        expect(unit.inherited_edit_users).not_to include(user.user_key)
        expect(unit.editors).not_to include(user.user_key)
      end
      it "should not remove users who do not have the editor role" do
        not_editor = FactoryBot.create(:unit_admin)
        unit.unit_admins = [not_editor.user_key]
        unit.edit_users = [not_editor.user_key]
        unit.inherited_edit_users = [not_editor.user_key]
        unit.remove_editor(not_editor.user_key)
        expect(unit.edit_users).to include(not_editor.user_key)
        expect(unit.inherited_edit_users).not_to include(user.user_key)
      end
    end
    describe "#editors_and_unit_admins" do
      it "should return all unit editors and unit admins" do
        unit.edit_users = [user.user_key, "pdinh"]
        unit.unit_administrators = [user.user_key]
        expect(unit.editors_and_unit_admins).to include(unit.editors.first)
        expect(unit.editors_and_unit_admins).to include(unit.unit_admins.first)
      end
    end
  end

  describe "depositors" do
    let!(:user) { FactoryBot.create(:user) }
    let!(:unit) { Admin::Unit.new }

    describe "#depositors" do
      it "should return the read_users" do
        unit.read_users = [user.user_key]
        expect(unit.depositors).to eq([user.user_key])
      end
    end
    describe "#depositors=" do
      it "should add depositors to the unit" do
        depositor_list = [FactoryBot.create(:user).user_key, FactoryBot.create(:user).user_key]
        unit.depositors = depositor_list
        expect(unit.depositors).to eq(depositor_list)
      end
      it "should call add_depositor" do
        depositor_list = [FactoryBot.create(:user).user_key, FactoryBot.create(:user).user_key]
        expect(unit).to receive("add_depositor").with(depositor_list[0])
        expect(unit).to receive("add_depositor").with(depositor_list[1])
        unit.depositors = depositor_list
      end
      it "should remove depositors from the unit" do
        name = user.user_key
        unit.depositors = [name]
        expect(unit.depositors).to eq([name])
        unit.depositors -= [name]
        expect(unit.depositors).to eq([])
      end
      it "should call remove_depositor" do
        unit.add_depositor(user.user_key)
        expect(unit).to receive("remove_depositor").with(user.user_key)
        unit.depositors = [FactoryBot.create(:user).user_key]
      end
    end
    describe "#add_depositor" do
      it "should give edit access to the unit" do
        not_depositor = FactoryBot.create(:user)
        unit.add_depositor(not_depositor.user_key)
        expect(unit.inherited_edit_users).to include(not_depositor.user_key)
        expect(unit.depositors).to include(not_depositor.user_key)
      end
    end
    describe "#remove_depositor" do
      it "should revoke edit access to the unit" do
        unit.add_depositor(user.user_key)
        unit.remove_depositor(user.user_key)
        expect(unit.inherited_edit_users).not_to include(user.user_key)
        expect(unit.depositors).not_to include(user.user_key)
      end
      it "should not remove users who do not have the depositor role" do
        not_depositor = FactoryBot.create(:unit_admin)
        unit.inherited_edit_users = [not_depositor.user_key]
        unit.remove_depositor(not_depositor.user_key)
        expect(unit.inherited_edit_users).to include(not_depositor.user_key)
      end
    end
  end

  describe "#inherited_edit_users" do
  end
  describe "#inherited_edit_users=" do
  end

  describe "default rights delegators" do
    let(:unit) { FactoryBot.create(:unit) }

    describe "users" do
      let(:users) { (1..3).map { Faker::Internet.email } }

      before :each do
        unit.default_read_users = users
        unit.save
      end

      it "should persist assigned #default_read_users" do
        expect(Admin::Unit.find(unit.id).default_read_users).to eq(users)
      end

      it "should persist empty #default_read_users" do
        unit.default_read_users = []
        unit.save
        expect(Admin::Unit.find(unit.id).default_read_users).to eq([])
      end
    end

    describe "groups" do
      let(:groups) { (1..3).map { Faker::Lorem.sentence(word_count: 4) } }

      before :each do
        unit.default_read_groups = groups
        unit.save
      end

      it "should persist assigned #default_read_groups" do
        expect(Admin::Unit.find(unit.id).default_read_groups).to eq(groups)
      end

      it "should persist empty #default_read_groups" do
        unit.default_read_groups = []
        unit.save
        expect(Admin::Unit.find(unit.id).default_read_groups).to eq([])
      end
    end

    describe 'visiblity' do
      it 'should default to private' do
        expect(unit.default_visibility).to eq 'private'
      end
      it 'should not override on create' do
        c = FactoryBot.create(:unit, default_visibility: 'public')
        expect(c.default_visibility).to eq 'public'
      end
    end
  end

  describe "callbacks" do
    describe "after_save reindex if name or unit has changed" do
      let!(:unit) { FactoryBot.create(:unit) }
      it 'should call reindex_members if name has changed' do
        unit.name = "New name"
        expect(unit).to be_name_changed
        expect(unit).to receive("reindex_members").and_return(nil)
        unit.save
      end

      it 'should not call reindex_members if name or unit has not been changed' do
        unit.description = "A different description"
        expect(unit).not_to be_name_changed
        expect(unit).not_to receive("reindex_members")
        unit.save
      end
    end
  end

  describe "reindex_members" do
    before do
      @unit = FactoryBot.create(:unit, items: 3)
    end
    it 'should queue a reindex job for all member objects' do
      @unit.reindex_members {}
      expect(ReindexJob).to have_been_enqueued.with(@unit.collection_ids)
    end
  end
end
