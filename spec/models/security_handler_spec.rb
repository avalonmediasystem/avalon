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

describe SecurityHandler, type: :model do
  let(:shim_secure_url) { "http://example.com/streaming/secure/id" }
  let(:shim_cookies) {{ 'key' => {value: 'cookie'} }}

  describe '.secure_url' do
    let(:url) { "http://example.com/streaming/id" }
    let(:context) {{ session: {}, target: 'abcd1234', protocol: "http" }}

    context 'with a shim' do
      before do
	SecurityHandler.rewrite_url { shim_secure_url }
      end

      after do
	SecurityHandler.instance_variable_set(:@shim, nil)
      end

      it 'prefers the shim' do
        expect(SecurityHandler.secure_url(url, context)).to eq shim_secure_url
      end
    end

    context 'without a shim' do
      it 'uses the SecurityService' do
        expect_any_instance_of(SecurityService).to receive(:rewrite_url).with(url, context)
        SecurityHandler.secure_url(url, context)
      end
    end
  end

  describe '.secure_cookies' do
    let(:context) {{ target: 'abcd1234', request_host: 'localhost' }}

    context 'with a shim' do
      before do
        SecurityHandler.create_cookies { shim_cookies }
      end

      after do
	SecurityHandler.instance_variable_set(:@cookie_shim, nil)
      end

      it 'prefers the shim' do
        expect(SecurityHandler.secure_cookies(context)).to eq shim_cookies
      end
    end

    context 'without a shim' do
      it 'uses the SecurityService' do
        expect_any_instance_of(SecurityService).to receive(:create_cookies).with(context)
        SecurityHandler.secure_cookies(context)
      end
    end
  end

  describe '.create_cookies' do
    before do
      SecurityHandler.create_cookies { shim_cookies }
    end

    after do
      SecurityHandler.instance_variable_set(:@cookie_shim, nil)
    end

    it 'stores a shim block' do
      expect(SecurityHandler.instance_variable_get(:@cookie_shim)).to be_present
    end
  end

  describe '.rewrite_url' do
    before do
      SecurityHandler.rewrite_url { shim_secure_url }
    end

    after do
      SecurityHandler.instance_variable_set(:@shim, nil)
    end

    it 'stores a shim block' do
      expect(SecurityHandler.instance_variable_get(:@shim)).to be_present
    end
  end
end
