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
require 'cancan/matchers'

RSpec.describe Timeline, type: :model do

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:visibility) }
    it { is_expected.to validate_inclusion_of(:visibility).in_array([Timeline::PUBLIC, Timeline::PRIVATE, Timeline::PRIVATE_WITH_TOKEN]) }
  end

  describe 'abilities' do
    subject{ ability }
    let(:ability){ Ability.new(user) }
    let(:user){ FactoryBot.create(:user) }

    context 'when administrator' do
      let(:user) { FactoryBot.create(:administrator) }
      let(:timeline) { FactoryBot.create(:timeline, user: user) }
      it{ is_expected.to be_able_to(:manage, timeline) }
      it{ is_expected.to be_able_to(:create, timeline) }
      it{ is_expected.to be_able_to(:read, timeline) }
      it{ is_expected.to be_able_to(:update, timeline) }
      it{ is_expected.to be_able_to(:delete, timeline) }
    end

    context 'when owner' do
      let(:timeline) { FactoryBot.create(:timeline, user: user) }

      it{ is_expected.to be_able_to(:manage, timeline) }
      it{ is_expected.to be_able_to(:duplicate, timeline)}
      it{ is_expected.to be_able_to(:create, timeline) }
      it{ is_expected.to be_able_to(:read, timeline) }
      it{ is_expected.to be_able_to(:update, timeline) }
      it{ is_expected.to be_able_to(:delete, timeline) }
    end

    context 'when other user' do
      context('timeline public') do
        let(:timeline) { FactoryBot.create(:timeline, visibility: Timeline::PUBLIC) }

        it{ is_expected.not_to be_able_to(:manage, timeline) }
        it{ is_expected.to be_able_to(:duplicate, timeline) }
        it{ is_expected.not_to be_able_to(:create, timeline) }
        it{ is_expected.to be_able_to(:read, timeline) }
        it{ is_expected.not_to be_able_to(:update, timeline) }
        it{ is_expected.not_to be_able_to(:delete, timeline) }
      end
      context('timeline private') do
        let(:timeline) { FactoryBot.create(:timeline, visibility: Timeline::PRIVATE) }

        it{ is_expected.not_to be_able_to(:manage, timeline) }
        it{ is_expected.not_to be_able_to(:duplicate, timeline) }
        it{ is_expected.not_to be_able_to(:create, timeline) }
        it{ is_expected.not_to be_able_to(:read, timeline) }
        it{ is_expected.not_to be_able_to(:update, timeline) }
        it{ is_expected.not_to be_able_to(:delete, timeline) }
      end
      context('timeline private with token') do
        let(:timeline) { FactoryBot.create(:timeline, visibility: Timeline::PRIVATE_WITH_TOKEN) }
        context('when no token given') do
          it{ is_expected.not_to be_able_to(:manage, timeline) }
          it{ is_expected.not_to be_able_to(:duplicate, timeline) }
          it{ is_expected.not_to be_able_to(:create, timeline) }
          # One is still not allowed to read the timeline, but the controller bypasses this when the token is passed as a query param
          it{ is_expected.not_to be_able_to(:read, timeline) }
          it{ is_expected.not_to be_able_to(:update, timeline) }
          it{ is_expected.not_to be_able_to(:delete, timeline) }
        end
        context('when token given') do
          let(:ability) { Ability.new(user, {timeline_token: timeline.access_token}) }
          it{ is_expected.not_to be_able_to(:manage, timeline) }
          it{ is_expected.to be_able_to(:duplicate, timeline) }
          it{ is_expected.not_to be_able_to(:create, timeline) }
          it{ is_expected.to be_able_to(:read, timeline) }
          it{ is_expected.not_to be_able_to(:update, timeline) }
          it{ is_expected.not_to be_able_to(:delete, timeline) }
        end
      end
    end
    context 'when not logged in' do
      let(:ability) { Ability.new(nil) }
      context('timeline public') do
        let(:timeline) { FactoryBot.create(:timeline, visibility: Timeline::PUBLIC) }

        it{ is_expected.not_to be_able_to(:manage, timeline) }
        it{ is_expected.not_to be_able_to(:duplicate, timeline) }
        it{ is_expected.not_to be_able_to(:create, timeline) }
        it{ is_expected.to be_able_to(:read, timeline) }
        it{ is_expected.not_to be_able_to(:update, timeline) }
        it{ is_expected.not_to be_able_to(:delete, timeline) }
      end
      context('timeline private') do
        let(:timeline) { FactoryBot.create(:timeline, visibility: Timeline::PRIVATE) }

        it{ is_expected.not_to be_able_to(:manage, timeline) }
        it{ is_expected.not_to be_able_to(:duplicate, timeline) }
        it{ is_expected.not_to be_able_to(:create, timeline) }
        it{ is_expected.not_to be_able_to(:read, timeline) }
        it{ is_expected.not_to be_able_to(:update, timeline) }
        it{ is_expected.not_to be_able_to(:delete, timeline) }
      end
      context('timeline private with token') do
        let(:timeline) { FactoryBot.create(:timeline, visibility: Timeline::PRIVATE_WITH_TOKEN) }
        context('when no token given') do
          it{ is_expected.not_to be_able_to(:manage, timeline) }
          it{ is_expected.not_to be_able_to(:duplicate, timeline) }
          it{ is_expected.not_to be_able_to(:create, timeline) }
          # One is still not allowed to read the timeline, but the controller bypasses this when the token is passed as a query param
          it{ is_expected.not_to be_able_to(:read, timeline) }
          it{ is_expected.not_to be_able_to(:update, timeline) }
          it{ is_expected.not_to be_able_to(:delete, timeline) }
        end
        context('when token given') do
          let(:ability) { Ability.new(nil, {timeline_token: timeline.access_token}) }
          it{ is_expected.not_to be_able_to(:manage, timeline) }
          it{ is_expected.not_to be_able_to(:duplicate, timeline) }
          it{ is_expected.not_to be_able_to(:create, timeline) }
          it{ is_expected.to be_able_to(:read, timeline) }
          it{ is_expected.not_to be_able_to(:update, timeline) }
          it{ is_expected.not_to be_able_to(:delete, timeline) }
        end
      end
    end
  end

  describe 'scopes' do
    describe 'by_user' do
      let(:user){ FactoryBot.create(:user) }
      let(:timeline_owner) { FactoryBot.create(:timeline, user: user) }
      let(:timeline) { FactoryBot.create(:timeline) }
      it 'returns timelines by user' do
        expect(Timeline.by_user(user)).to include(timeline_owner)
      end
      it 'does not return timelines by another user' do
        expect(Timeline.by_user(user)).not_to include(timeline)
      end
    end
    describe 'title_like' do
      let(:timeline1) { FactoryBot.create(:timeline, title: 'Moose tunes') }
      let(:timeline2) { FactoryBot.create(:timeline, title: 'My favorite by smoose') }
      let(:timeline3) { FactoryBot.create(:timeline, title: 'Favorites') }
      let(:title_filter) { 'moose' }
      it 'returns timelines with matching titles' do
        # Commented out since case insensitivity is default for mysql but not postgres
        # expect(Timeline.title_like(title_filter)).to include(timeline1)
        expect(Timeline.title_like(title_filter)).to include(timeline2)
      end
      it 'does not return timelines without matching titles' do
        expect(Timeline.title_like(title_filter)).not_to include(timeline3)
      end
    end
    describe 'with_tag' do
      let(:timeline1) { FactoryBot.create(:timeline, tags: ['Moose']) }
      let(:timeline2) { FactoryBot.create(:timeline, tags: ['Goose', 'moose']) }
      let(:timeline3) { FactoryBot.create(:timeline, tags: ['smoose', 'Goose']) }
      let(:timeline4) { FactoryBot.create(:timeline, tags: ['Goose']) }
      let(:tag_filter) { 'moose' }
      it 'returns timelines with exact matching tags' do
        # Commented out since case insensitivity is default for mysql but not postgres
        # expect(Timeline.with_tag(tag_filter)).to include(timeline1)
        expect(Timeline.with_tag(tag_filter)).to include(timeline2)
      end
      it 'does not return timelines with partial matching tag' do
        expect(Timeline.with_tag(tag_filter)).not_to include(timeline3)
      end
      it 'does not return timelines with without the tag' do
        expect(Timeline.with_tag(tag_filter)).not_to include(timeline4)
      end
    end
  end

  describe 'synchronize_title' do
    let(:master_file) { FactoryBot.create(:master_file) }
    let(:source) { Rails.application.routes.url_helpers.master_file_url(master_file.id, params: { t: "0," }) }
    let(:timeline) { FactoryBot.create(:timeline, title: "Old title", source: source, manifest: nil) }
    let(:new_title) { "New Title" }

    context 'when the manifest title changes' do
      before do
        manifest_json = JSON.parse(timeline.manifest)
        manifest_json["label"]["en"] = [new_title]
        timeline.manifest = manifest_json.to_json
      end
      it 'updates the title' do
        expect(timeline.manifest_changed?).to eq true
        timeline.synchronize_title
        expect(timeline.title).to eq new_title
      end
    end
    context 'when the title changes' do
      before do
        timeline.title = new_title
      end

      it 'updates the manifest title' do
        expect(timeline.title_changed?).to eq true
        timeline.synchronize_title
        manifest_json = JSON.parse(timeline.manifest)
        expect(manifest_json["label"]["en"].first).to eq new_title
      end
    end
  end

  describe 'synchronize_description' do
    let(:master_file) { FactoryBot.create(:master_file) }
    let(:source) { Rails.application.routes.url_helpers.master_file_url(master_file.id, params: { t: "0," }) }
    let(:timeline) { FactoryBot.create(:timeline, description: "Old description", source: source, manifest: nil) }
    let(:new_description) { "New description" }

    context 'when the manifest description changes' do
      before do
        manifest_json = JSON.parse(timeline.manifest)
        manifest_json["summary"] ||= {}
        manifest_json["summary"]["en"] = [new_description]
        timeline.manifest = manifest_json.to_json
      end
      it 'updates the description' do
        expect(timeline.manifest_changed?).to eq true
        timeline.synchronize_description
        expect(timeline.description).to eq new_description
      end
    end
    context 'when the description changes' do
      before do
        timeline.description = new_description
      end

      it 'updates the manifest description' do
        expect(timeline.description_changed?).to eq true
        timeline.synchronize_description
        manifest_json = JSON.parse(timeline.manifest)
        expect(manifest_json["summary"]["en"].first).to eq new_description
      end
    end
  end

  describe 'standardize_source' do
    let(:permalink) { "http://permalink/12345" }
    let(:media_fragment) { "0," }
    let(:master_file) { FactoryBot.create(:master_file, permalink: "http://permalink/12345") }
    let(:source) { Rails.application.routes.url_helpers.master_file_path(master_file.id) + "?t=#{media_fragment}" }
    let(:timeline) { FactoryBot.build(:timeline, description: "Old description", source: source, manifest: nil) }
    let(:standardized_source) { Rails.application.routes.url_helpers.master_file_url(master_file.id) + "?t=#{media_fragment}" }

    context 'when creating a manifest' do
      it 'updates the manifest homepage' do
        expect(timeline.source_changed?).to eq true
        expect { timeline.save }.to change { timeline.source }.from(source).to(standardized_source)
      end
    end

    context 'when the source changes' do
      let(:new_media_fragment) { "10,100" }
      let(:new_source) { Rails.application.routes.url_helpers.master_file_path(master_file.id) + "?t=#{new_media_fragment}" }
      let(:standardized_source) { Rails.application.routes.url_helpers.master_file_url(master_file.id) + "?t=#{new_media_fragment}" }
      before do
        timeline.save
        timeline.source = new_source
      end

      it 'updates the manifest homepage' do
        expect(timeline.source_changed?).to eq true
        expect { timeline.standardize_source }.to change { timeline.source }.from(new_source).to(standardized_source)
      end
    end
  end

  describe 'standardize_homepage' do
    let(:permalink) { "http://permalink/12345" }
    let(:media_fragment) { "0," }
    let(:master_file) { FactoryBot.create(:master_file, permalink: "http://permalink/12345") }
    let(:source) { Rails.application.routes.url_helpers.master_file_url(master_file.id) + "?t=#{media_fragment}" }
    let(:timeline) { FactoryBot.build(:timeline, description: "Old description", source: source, manifest: nil) }
    let(:new_homepage) { "#{permalink}?t=#{media_fragment}" }

    context 'when creating a manifest' do
      it 'updates the manifest homepage' do
        expect(timeline.source_changed?).to eq true
        timeline.save
        manifest_json = JSON.parse(timeline.manifest)
        expect(manifest_json["homepage"]["id"]).to eq new_homepage
      end
    end

    context 'when the source changes' do
      let(:new_media_fragment) { "10,100" }
      let(:new_homepage) { "#{permalink}?t=#{new_media_fragment}" }
      before do
        timeline.save
        timeline.source = Rails.application.routes.url_helpers.master_file_path(master_file.id) + "?t=#{new_media_fragment}"
      end

      it 'updates the manifest homepage' do
        expect(timeline.source_changed?).to eq true
        timeline.standardize_homepage
        manifest_json = JSON.parse(timeline.manifest)
        expect(manifest_json["homepage"]["id"]).to eq new_homepage
      end
    end
  end
end
