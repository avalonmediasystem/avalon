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

describe TempfileFactory do
  class MockApp
    def call(env)
      [200, {}, env]
    end
  end

  let(:file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'videoshort.mp4'), 'video/mp4')}
  let(:env) { Rack::MockRequest.env_for('/', method: :post, params: file) }
  let(:app) { MockApp.new }
  subject { TempfileFactory.new(app) }

  context "when an alternate directory is defined" do
    it "sets `env['rack.multipart.tempfile_factory']`" do
      without_partial_double_verification do
        allow(Settings.tempfile).to receive(:location).and_return(Rails.root.join('spec', 'fixtures').to_s)
        subject.instance_variable_set(:@tempfile_location, Settings.tempfile.location)
        status, headers, response = subject.call(env)
        expect(response).to include 'rack.multipart.tempfile_factory'
      end
    end
  end

  context "when an alternate directory is NOT defined" do
    it "does not set `env['rack.multipart.tempfile_factory']`" do
      without_partial_double_verification do
        allow(Settings.tempfile).to receive(:location).and_return(nil)
        subject.instance_variable_set(:@tempfile_location, Settings.tempfile.location)
        status, headers, response = subject.call(env)
        expect(response).to_not include 'rack.multipart.tempfile_factory'
      end
    end
  end

  context "when there is a problem with the defined alternate directory" do
    it "does not set `env['rack.multipart.tempfile_factory']`" do
      without_partial_double_verification do
        allow(Settings.tempfile).to receive(:location).and_return('does not exist')
        subject.instance_variable_set(:@tempfile_loaction, Settings.tempfile.location)
        status, headers, response = subject.call(env)
        expect(response).to_not include 'rack.multipart.tempfile_factory'
      end
    end
  end
end