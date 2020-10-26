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

describe User, :clean do
  subject { user }
  let(:user) { FactoryBot.build(:user) }
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

  describe 'from omniauth' do
    before do
      # User must exists before tests can run
      described_class.create(provider:     'shibboleth',
                             uid:          'brianbboys1967',
                             ppid:         'P0000001',
                             display_name: 'Brian Wilson',
                             email:        'brianbboys1967@emory.edu',
                             username:     'P0000001')
    end

    let(:auth_hash) do
      OmniAuth::AuthHash.new(
        provider: 'shibboleth',
        uid:      "P0000001",
        info:     {
          display_name: "Brian Wilson",
          uid:          'brianbboys1967'
        }
      )
    end

    let(:user) { described_class.from_omniauth(auth_hash) }

    context "has attributes" do
      it "has Shibboleth as a provider" do
        expect(user.provider).to eq 'shibboleth'
      end
      it "has a uid" do
        expect(user.uid).to eq auth_hash.info.uid
      end
      it "has a name" do
        expect(user.display_name).to eq auth_hash.info.display_name
      end
      it "has a PPID" do
        expect(user.ppid).to eq auth_hash.uid
      end
    end

    context "updating an existing user" do
      let(:updated_auth_hash) do
        OmniAuth::AuthHash.new(
          provider: 'shibboleth',
          uid:      "P0000001",
          info:     {
            display_name: "Boaty McBoatface",
            uid:          'brianbboys1968'
          }
        )
      end

      it "updates ppid and display_name with values from shibboleth" do
        expect(user.uid).to eq auth_hash.info.uid
        expect(user.ppid).to eq auth_hash.uid
        expect(user.display_name).to eq auth_hash.info.display_name
        described_class.from_omniauth(updated_auth_hash)
        user.reload
        expect(user.ppid).to eq updated_auth_hash.uid
        expect(user.uid).not_to eq auth_hash.info.uid
        expect(user.ppid).to eq updated_auth_hash.uid
        expect(user.display_name).not_to eq auth_hash.info.display_name
        expect(user.display_name).to eq updated_auth_hash.info.display_name
      end
    end

    context "signing in twice" do
      it "finds the original account instead of trying to make a new one" do
        # login existing user second time
        expect { described_class.from_omniauth(auth_hash) }
          .not_to change { described_class.count }
      end
    end

    context "attempting to sign in a new user" do
      let(:new_auth_hash) do
        OmniAuth::AuthHash.new(
          provider: 'shibboleth',
          uid:      'P0000003',
          info:     {
            display_name: 'Fake Person',
            uid:          'egnetid'
          }
        )
      end

      it "does not allow a new user to sign in" do
        expect { described_class.from_omniauth(new_auth_hash) }
          .not_to change { described_class.count }
        expect(Rails.logger).to receive(:error)
        u = described_class.from_omniauth(new_auth_hash)
        expect(u.class.name).to eql 'User'
        expect(u.persisted?).to be false
      end
    end

    context "invalid shibboleth data" do
      let(:invalid_auth_hash) do
        OmniAuth::AuthHash.new(
          provider: 'shibboleth',
          uid:      '',
          info:     {
            display_name: '',
            uid:          ''
          }
        )
      end

      it "does not register new users" do
        expect { described_class.from_omniauth(invalid_auth_hash) }
          .not_to change { described_class.count }
        expect(Rails.logger).to receive(:error)
        u = described_class.from_omniauth(invalid_auth_hash)
        expect(u.class.name).to eql 'User'
        expect(u.persisted?).to be false
      end
    end
  end
end
