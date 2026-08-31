# Copyright 2011-2026, The Trustees of Indiana University and Northwestern
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

describe '/master_files/' do
  describe "#transcript" do
    let(:user) { FactoryBot.create(:administrator) }
    let(:master_file) { FactoryBot.create(:master_file, supplemental_files: [supplemental_file]) }
    let(:supplemental_file) { FactoryBot.create(:supplemental_file, :with_transcript_file, :with_transcript_tag, label: 'transcript') }

    before do
      allow(Settings.supplemental_files).to receive(:proxy).and_return(true)
    end

    it 'serves transcript file content' do
      sign_in(user)
      expect(master_file.supplemental_files.first['tags']).to eq (["transcript"])
      get "/master_files/#{master_file.id}/transcript/#{supplemental_file.id}"
      expect(response).to have_http_status(301)
      follow_redirect! # Redirect to supplemental files path
      expect(response.headers['Content-Type']).to eq('text/vtt')
      expect(response).to have_http_status(:ok)
      expect(response.body.include? "Example captions").to be_truthy
    end

    context 'read from solr' do
      it 'should not read from fedora' do
        master_file
        perform_enqueued_jobs(only: MediaObjectIndexingJob)
        WebMock.reset_executed_requests!
        sign_in(user)
        get "/master_files/#{master_file.id}/transcript/#{supplemental_file.id}"
        expect(response).to have_http_status(301)
        follow_redirect! # Redirect to supplemental files path
        expect(a_request(:any, /#{ActiveFedora.fedora.base_uri}/)).not_to have_been_made
      end
    end
  end
end
