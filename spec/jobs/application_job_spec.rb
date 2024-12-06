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

describe ApplicationJob do
  describe 'exception handling' do
    it 'rescues Ldp::Gone errors' do
      allow_any_instance_of(described_class).to receive(:perform).and_raise(Ldp::Gone)
      allow_any_instance_of(Exception).to receive(:backtrace).and_return(["Test trace"])
      expect(Rails.logger).to receive(:error).with('Ldp::Gone\nTest trace')
      expect { described_class.perform_now }.to_not raise_error
    end

    context 'raise_on_connection_error disabled' do
      let(:request_context) { { uri: Addressable::URI.parse("http://example.com"), body: "request_context" } }
      let(:e) { { body: "error_response" } }

      [RSolr::Error::ConnectionRefused, RSolr::Error::Timeout, Blacklight::Exceptions::ECONNREFUSED, Faraday::ConnectionFailed].each do |error_code|
        it "rescues #{error_code} errors" do
          raised_error = if error_code == RSolr::Error::ConnectionRefused
                           error_code.new(request_context)
                         elsif error_code == RSolr::Error::Timeout
                           error_code.new(request_context, e)
                         else
                           error_code
                         end
          allow(Settings.app_job.solr_and_fedora).to receive(:raise_on_connection_error).and_return(false)
          allow_any_instance_of(described_class).to receive(:perform).and_raise(raised_error)
          allow_any_instance_of(Exception).to receive(:backtrace).and_return(["Test trace"])
          allow_any_instance_of(Exception).to receive(:message).and_return('Connection reset by peer')
          expect(Rails.logger).to receive(:error).with(error_code.to_s + ': Connection reset by peer\nTest trace')
          expect { described_class.perform_now }.to_not raise_error
        end
      end
    end

    context 'raise_on_connection_error enabled' do
      let(:request_context) { { uri: Addressable::URI.parse("http://example.com"), body: "request_context" } }
      let(:e) { { body: "error_response" } }

      [RSolr::Error::ConnectionRefused, RSolr::Error::Timeout, Blacklight::Exceptions::ECONNREFUSED, Faraday::ConnectionFailed].each do |error_code|
        it "raises #{error_code} errors" do
          raised_error = if error_code == RSolr::Error::ConnectionRefused
                           error_code.new(request_context)
                         elsif error_code == RSolr::Error::Timeout
                           error_code.new(request_context, e)
                         else
                           error_code
                         end 
          allow(Settings.app_job.solr_and_fedora).to receive(:raise_on_connection_error).and_return(true)
          allow_any_instance_of(described_class).to receive(:perform).and_raise(raised_error)
          allow_any_instance_of(Exception).to receive(:backtrace).and_return(["Test trace"])
          allow_any_instance_of(Exception).to receive(:message).and_return('Connection reset by peer')
          expect { described_class.perform_now }.to raise_error(error_code, 'Connection reset by peer')
        end
      end
    end
  end
end
