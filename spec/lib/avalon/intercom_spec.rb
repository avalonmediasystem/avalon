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
require 'avalon/intercom'

describe Avalon::Intercom do
  before :each do
    Settings.intercom = {
      'default' => {
        'url' => 'https://target.avalon.com/',
        'api_token' => 'a_valid_token',
        'import_bib_record' => true,
        'publish' => false,
        'push_label' => 'Push to Target'
      }
    }
  end
  after :each do
    Settings.intercom = nil
  end

  let!(:username) { 'test_username' }
  let!(:user_collections) {
    [{"id"=>"cupcake_collection",
      "name"=>"The Art and History of Cupcakes",
      "unit"=>"Default Unit",
      "description"=>"",
      "object_count"=>{"total"=>9, "published"=>2, "unpublished"=>7},
      "roles"=>{"managers"=>["archivist1@example.com"], "editors"=>[], "depositors"=>[]}
    }]
  }
  let!(:intercom) { Avalon::Intercom.new(username) }
  let!(:request) {
    stub_request(:get, "https://target.avalon.com/admin/collections.json?user=test_username&per_page=1152921504606846976").to_return(
        status: 200,
        body: user_collections.to_json,
        headers: { content_type: 'application/json;' }
      )
  }

  describe 'user_collections' do
    it "should return correct collections for user" do
      response = intercom.user_collections
      expect(response).to eq([{"id"=>"cupcake_collection", "name"=>"The Art and History of Cupcakes"}])
    end
  end
  describe 'collection_valid?' do
    it "should return true for valid collection" do
      response = intercom.collection_valid? 'cupcake_collection'
      expect(response).to be true
    end
    it "should return false for invalid collection" do
      response = intercom.collection_valid? 'invalid_collection'
      expect(response).to be false
    end
  end
  describe 'push_media_object' do
    let(:media_object) { FactoryBot.create(:media_object) }
    let(:master_file_with_structure) { FactoryBot.create(:master_file, :with_structure, media_object: media_object) }

    it "should respond to unpermitted collection with error" do
      response = intercom.push_media_object(media_object, 'invalid_collection', false)
      expect(response[:message]).to eq('You are not authorized to push to this collection.')
    end
    it "should respond to unconfigured intercom with error" do
      Settings.intercom = {}
      response = Avalon::Intercom.new(username).push_media_object(media_object, 'cupcake_collection', false)
      expect(response[:message]).to eq('Avalon intercom target is not configured.')
    end
    it "should respond to a failed api call with error, while the media object push status shall be false" do
      allow(RestClient::Request).to receive(:execute).and_call_original
      allow(RestClient::Request).to receive(:execute).with(hash_including(method: :post)).and_raise(StandardError)
      response = intercom.push_media_object(media_object, 'cupcake_collection', false)
      expect(response).to eq({ message: 'StandardError', status: 500 })
      expect(media_object.intercom_pushed?).eql?(false)
    end
    it "should respond with a link to the pushed object on target, while the pushed content shall not include any intercom notes, and the media object push status shall be true" do
      media_object.ordered_master_files=[master_file_with_structure]
      media_object_hash = media_object.to_ingest_api_hash(false)
      expect(media_object_hash[:fields][:note]).eql?(nil)
      expect(media_object_hash[:fields][:notetype]).eql?(nil)
      media_object_hash.merge!(
        { 'collection_id' => 'cupcake_collection', 'import_bib_record' => true, 'publish' => false }
      )
      media_object_json = media_object_hash.to_json
      stub_request(:post, "https://target.avalon.com/media_objects.json").
        with(body: media_object_json).to_return(status: 200, body: { 'id' => 'def456' }.to_json, headers: {})
      response = intercom.push_media_object(media_object, 'cupcake_collection', false)
      expect(response).to eq({ link: 'https://target.avalon.com/media_objects/def456'})
      expect(media_object.intercom_pushed?).eql?(true)
    end
  end
end
