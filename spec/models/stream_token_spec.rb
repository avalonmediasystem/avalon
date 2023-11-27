# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

describe StreamToken do
  include ActiveSupport::Testing::TimeHelpers

  let(:target) { '232A9B17-CCA8-4368-9599-117D2AF1D2EC' }

  describe 'existing session' do
    let(:session) { { session_id: '00112233445566778899aabbccddeeff' } }

    it 'should create a token' do
      expect(StreamToken.find_or_create_session_token(session, target)).to match(/^[0-9a-f]{40}$/)
    end

    it 'stores the token in the session' do
      token = StreamToken.find_or_create_session_token(session, target)
      expect(session[:hash_tokens]).to include token
    end

    it 'stores the token once in the session' do
      token = StreamToken.find_or_create_session_token(session, target)
      token2 = StreamToken.find_or_create_session_token(session, target)
      expect(token).to eq token2
      expect(session[:hash_tokens].count(token)).to eq 1
    end

    context '#get_session_tokens_for' do
      let(:targets) { ['D1452CB7-4DC2-4A26-AC2C-FBCE943C164C', target] }

      it 'should create the tokens' do
        expect(StreamToken.get_session_tokens_for(session: session, targets: targets)).to match_array([be_instance_of(StreamToken), be_instance_of(StreamToken)])
      end

      it 'stores the tokens in the session' do
        tokens = StreamToken.get_session_tokens_for(session: session, targets: targets)
        expect(session[:hash_tokens]).to include *tokens.pluck(:token)
      end

      it 'stores the tokens once in the session' do
        tokens = StreamToken.get_session_tokens_for(session: session, targets: targets)
        tokens2 = StreamToken.get_session_tokens_for(session: session, targets: targets)
        expect(tokens).to eq tokens2
        expect(session[:hash_tokens].count(tokens.first.token)).to eq 1
        expect(session[:hash_tokens].count(tokens.second.token)).to eq 1
      end

      it 'updates expires' do
        StreamToken.get_session_tokens_for(session: session, targets: targets)
        expect { StreamToken.get_session_tokens_for(session: session, targets: targets) }.not_to change { StreamToken.count }
        expect { StreamToken.get_session_tokens_for(session: session, targets: targets) }.to change { StreamToken.pluck(:expires) }
      end

      context 'with a mix of existing and new tokens' do
        before { StreamToken.get_session_tokens_for(session: session, targets: [target]) }

        it 'creates and stores the token' do
          tokens = StreamToken.get_session_tokens_for(session: session, targets: targets)
          expect(tokens).to match_array([be_instance_of(StreamToken), be_instance_of(StreamToken)])
          expect(session[:hash_tokens]).to include *tokens.pluck(:token)
        end
      end
    end
  end

  describe 'valid_token?' do
    let(:session) { { session_id: '00112233445566778899aabbccddeeff' } }
    let(:token) { StreamToken.find_by_token(StreamToken.find_or_create_session_token(session, target)) }

    it 'returns false for token with no value' do
      expect(StreamToken.valid_token?(nil, '')).to be_falsey
    end
    it 'returns false if the token found has expired' do
      token.expires = Time.now.utc
      token.save!
      expect(StreamToken.valid_token?(token.token, token.target)).to be_falsey
    end
    it 'returns false if the token target does not match' do
      expect(StreamToken.valid_token?(token.token, 'some other id')).to be_falsey
    end
    it 'returns true if token found has not expired and is for the correct master_file' do
      expect(StreamToken.valid_token?(token.token, token.target)).to be_truthy
    end
  end

  describe 'new session' do
    let(:session) { {} }

    it 'should create a token' do
      expect(StreamToken.find_or_create_session_token(session, target)).to match(/^[0-9a-f]{40}$/)
    end
  end

  describe 'delete session' do
    let(:session) { { session_id: '00112233445566778899aabbccddeeff' } }
    describe 'tokens exist' do
      let!(:token) { StreamToken.find_or_create_session_token(session, target) }
      it 'should delete existing tokens' do
        optional "Sometimes throws RangeError for ActiveRecord::Type::Integer with limit 4" if ENV['CI']
        StreamToken.logout! session
        expect(StreamToken.exists?(token)).to be_falsey
      end
    end
    describe "tokens don't exist" do
      it 'should not bomb' do
        expect { StreamToken.logout! session }.not_to change { StreamToken.count }
      end
    end
  end

  describe 'purge_expired!' do
    let(:session) { { session_id: '00112233445566778899aabbccddeeff' } }
    let!(:token) { StreamToken.find_or_create_session_token(session, target) }

    it 'removes purged tokens from session' do
      travel_to StreamToken.find_by(token: token).expires + 1.minute do
        StreamToken.purge_expired!(session)
        expect(session[:hash_tokens]).not_to include(token)
      end
    end
  end
end
