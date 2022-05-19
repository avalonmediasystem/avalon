# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

describe User do
  subject { user }
  let!(:user) { FactoryBot.build(:user) }
  let!(:list) { 0.upto(rand(5)).collect { Faker::Internet.email } }

  describe "validations" do
    it {is_expected.to validate_presence_of(:username)}
    it {is_expected.to validate_uniqueness_of(:username).case_insensitive}
    it {is_expected.to validate_presence_of(:email)}
    it {is_expected.to validate_uniqueness_of(:email).case_insensitive}

    context 'username and email uniqueness' do
      let(:username) { Faker::Internet.username }
      let(:email) { Faker::Internet.email }

      context "using an already used email for a username" do
        let!(:user) { FactoryBot.create(:user, username: username, email: email) }
        let(:user2) { FactoryBot.build(:user, username: email) }
        it "is invalid" do
          expect(user2).not_to be_valid
          expect(user2.errors[:username]).to include "is taken."
        end
      end

      context "using an already used username for an email" do
        let(:username) { Faker::Internet.email }
        let!(:user) { FactoryBot.create(:user, username: username, email: email) }
        let(:user2) { FactoryBot.build(:user, email: username) }
        it "is invalid" do
          expect(user2).not_to be_valid
          expect(user2.errors[:email]).to include "is taken."
        end
      end

      context "using email for username" do
        let!(:user) { FactoryBot.create(:user, username: email, email: email) }
        it "is valid" do
          expect(user).to be_valid
          expect(user.errors).to be_empty
        end
      end

      context "updating" do
        let!(:user) { FactoryBot.create(:user, username: username, email: email) }
        it "is valid" do
          user.username = "new.username"
          expect(user).to be_valid
          expect(user.errors).to be_empty
          user.email = "new.email@example.com"
          expect(user).to be_valid
          expect(user.errors).to be_empty
        end
      end
    end
  end

  describe "scopes" do
    describe 'user_like' do
      let(:user1) { FactoryBot.create(:user, username: 'alice.archivist') }
      let(:user2) { FactoryBot.create(:user, username: 'bob.user') }
      let(:user3) { FactoryBot.create(:user, username: 'charlie.manager') }
      let(:username_filter) { 'alice' }
      it 'returns users with matching usernames' do
        expect(User.username_like(username_filter)).to include(user1)
      end
      it 'does not return users without matching usernames' do
        expect(User.username_like(username_filter)).not_to include(user2)
      end
    end

    describe 'email_like' do
      let(:user1) { FactoryBot.create(:user, email: 'alice.archivist@example.edu') }
      let(:user2) { FactoryBot.create(:user, email: 'bob.user@example.edu') }
      let(:user3) { FactoryBot.create(:user, email: 'charlie.user@example.edu') }
      let(:email_filter) { 'user' }
      it 'returns users with matching emails' do
        expect(User.email_like(email_filter)).to include(user2)
        expect(User.email_like(email_filter)).to include(user3)
      end
      it 'does not return users without matching usernames' do
        expect(User.email_like(email_filter)).not_to include(user1)
      end
    end

    # describe 'group_like' do
    #   let(:user1) { FactoryBot.create(:admin) }
    #   let(:user2) { FactoryBot.create(:group_manager) }
    #   let(:user3) { FactoryBot.create(:manager) }
    #   let(:group_filter) { 'administrator' }
    #   it 'returns users with matching groups' do
    #     byebug
    #     expect(User.group_like(group_filter)).to include(user1)
    #   end
    #   it 'does not return users without matching groups' do
    #     expect(User.group_like(group_filter)).not_to include(user2)
    #     expect(User.group_like(group_filter)).not_to include(user3)
    #   end
    # end

    describe 'status_like' do
      let(:user1) { FactoryBot.create(:user, invitation_token: 'Accepted') }
      let(:user2) { FactoryBot.create(:user, invitation_token: 'Pending') }
      let(:status_filter) { 'Accepted' }
      it 'returns users with matching status' do
        expect(User.status_like(status_filter)).to include(user1)
      end
      it 'does not return users without matching status' do
        expect(User.status_like(status_filter)).not_to include(user2)
      end
    end

    describe 'provider_like' do
      let(:user1) { FactoryBot.create(:user, provider: 'Indiana University') }
      let(:user2) { FactoryBot.create(:user, provider: 'Northwestern') }
      let(:provider_filter) { 'Indiana' }
      it 'returns users with matching provider' do
        expect(User.provider_like(provider_filter)).to include(user1)
      end
      it 'does not return users without matching provider' do
        expect(User.provider_like(provider_filter)).not_to include(user2)
      end
    end
  end

  describe "Membership" do
    it "should be a member if its key is in the list" do
      expect(user).to be_in(list,[user.user_key])
      expect(user).to be_in(list+[user.user_key])
    end

    it "should not be a member if its key is not in the list" do
      expect(user).not_to be_in(list)
    end
  end

  describe "finders" do
    before do
      user.save
    end

    it "should find undeleted users by usernames" do
      found_user = User.find_or_create_by_username_or_email(user.username, nil)
      expect(found_user).to eq(user)
    end

    it "should find undeleted users by email" do
      found_user = User.find_or_create_by_username_or_email(user.username, nil)
      expect(found_user).to eq(user)
    end
  end

  describe "#groups" do
    let(:groups) { ["foorole"] }
    let(:role_map) { { "foorole" => [user.user_key] } }
    it "should return groups from the role map" do
      allow(RoleMapper).to receive(:map).and_return(role_map)
      expect(user.groups).to eq(groups)
    end
  end

  describe "#ldap_groups" do
    before do
      stub_const("Avalon::GROUP_LDAP", Net::LDAP.new)
      stub_const("Avalon::GROUP_LDAP_TREE", 'ou=Test,dc=avalonmediasystem,dc=org'.freeze)
    end
    it "should return [] if LDAP is not configured" do
      hide_const("Avalon::GROUP_LDAP")
      expect(user.send(:ldap_groups)).to eq([])
    end
    it "user should belong to Group1 and Group2 in mock LDAP" do
      entry = Net::LDAP::Entry.new("cn=user,dc=ads,dc=example,dc=edu")
      entry["memberof"] = ['CN=Group1,DC=ads,DC=example,DC=edu"','CN=Group2,DC=ads,DC=example,DC=edu"']
      allow_any_instance_of(Net::LDAP).to receive(:search).and_return([entry])
      expect(user.send(:ldap_groups)).to eq(['Group1','Group2'])
    end
  end

  describe "#autocomplete" do
    it "should return results of same type as user_key (email xor username)" do
      user.save(validate: false)
      expect(User.autocomplete(user.user_key)).to eq([{id: user.user_key, display: user.user_key}])
    end
  end

  describe "#destroy" do
    it 'removes bookmarks for user' do
      user = FactoryBot.create(:public)
      bookmark = Bookmark.create(document_id: Faker::Number.digit, user: user)
      expect { user.destroy }.to change { Bookmark.exists? bookmark.id }.from( true ).to( false )
    end
  end

  describe '#timeline_tags' do
    let(:user) { FactoryBot.create(:public) }

    it 'is empty when the user has no timeline tags' do
      expect(user.timeline_tags).to be_empty
    end

    it 'is a list of timeline tags' do
      timeline = FactoryBot.create(:timeline, user: user)
      expect(user.timeline_tags).to match_array timeline.tags
    end

    it 'does not contain duplicates' do
      FactoryBot.create(:timeline, user: user, tags: ['foo'])
      FactoryBot.create(:timeline, user: user, tags: ['foo'])
      expect(user.timeline_tags).to eq ['foo']
    end
  end
end
