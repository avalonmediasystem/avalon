# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

  let(:file) { fixture_file_upload("videoshort.mp4", "video/mp4") }
  let(:env) { Rack::MockRequest.env_for('/', method: :post, params: file) }
  let(:app) { MockApp.new }
  subject { TempfileFactory.new(app) }

  around do |example|
    @old_config = Settings.dig(:tempfile, :location)
    if tempfile_config.present?
      Settings.tempfile ||= Config::Options.new
      Settings.tempfile.location = tempfile_config
    else
      Settings.tempfile = nil
    end
    example.run
    if @old_config.present?
      Settings.tempfile ||= Config::Options.new
      Settings.tempfile.location = @old_config
    else
      Settings.tempfile = nil
    end
  end

  context "when an alternate directory is defined" do
    let(:tempfile_config) { Rails.root.join('spec', 'fixtures').to_s }

    it "sets `env['rack.multipart.tempfile_factory']`" do
      status, headers, response = subject.call(env)
      expect(response).to include 'rack.multipart.tempfile_factory'
      expect(response['rack.multipart.tempfile_factory'].call("videoshort.mp4", "video/mp4").path).to start_with(tempfile_config)
    end
  end

  context "when an alternate directory is NOT defined" do
    let(:tempfile_config) { nil }

    it "does not set `env['rack.multipart.tempfile_factory']`" do
      status, headers, response = subject.call(env)
      expect(response).to_not include 'rack.multipart.tempfile_factory'
    end
  end

  context "when there is a problem with the defined alternate directory" do
    let(:tempfile_config) { 'does not exist' }
    let(:logger) { double() }

    before do
      allow_any_instance_of(TempfileFactory).to receive(:logger).and_return(logger)
    end

    it "does not set `env['rack.multipart.tempfile_factory']`" do
      expect(logger).to receive(:warn).with(match("Falling back"))
      status, headers, response = subject.call(env)
      expect(response).to_not include 'rack.multipart.tempfile_factory'
    end
  end
end
