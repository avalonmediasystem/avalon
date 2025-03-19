# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

describe CleanupStreamTokenJob do
  let(:session) { { session_id: '00112233445566778899aabbccddeeff' } }
  let!(:valid_token) { StreamToken.find_or_create_session_token(session, 1.to_s) }
  let!(:expired_token1) { StreamToken.find_or_create_session_token(session, 2.to_s) }
  let!(:expired_token2) { StreamToken.find_or_create_session_token(session, 3.to_s) }

  describe 'perform' do
    it 'deletes all expired tokens' do
      expect(StreamToken.count).to eq 3
      [expired_token1, expired_token2].each do |token|
        stream_token = StreamToken.find_by_token(token)
        stream_token.update_attribute :expires, Time.now.utc
      end
      CleanupStreamTokenJob.perform_now
      expect(StreamToken.count).to eq 1
      expect(StreamToken.find_by_token(expired_token1)).to be_nil
      expect(StreamToken.find_by_token(expired_token2)).to be_nil
      expect(StreamToken.find_by_token(valid_token)).not_to be_nil
    end
  end
end
