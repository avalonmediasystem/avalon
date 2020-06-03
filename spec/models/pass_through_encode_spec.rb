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

# frozen_string_literal: true
require 'rails_helper'
require 'fakefs/safe'

describe PassThroughEncode do
  let(:master_file) { FactoryBot.create(:master_file) }
  let(:encode) do
    described_class.new("s3://bucket/sample.mp4",
      master_file_id: master_file.id,
      outputs: [{ label: "high", url: "s3://bucket/sample.high.mp4" }],
      preset: "pass_through"
    )
  end

  before do
    allow(MasterFile).to receive(:find).with(master_file.id).and_return(master_file)
  end

  describe 'create' do
    context 'with Minio' do
      let!(:altered_input) { "/tmp/1234/sample.mp4" }
      let!(:altered_output) { "/tmp/1234/sample.high.mp4" }
      let(:running_encode) do
        described_class.new(altered_input, outputs: [{ label: "high", url: altered_output }]).tap do |e|
          e.id = SecureRandom.uuid
          e.state = :running
          e.created_at = Time.zone.now
          e.updated_at = Time.zone.now
        end
      end

      before do
        Settings.minio = double("minio", endpoint: "http://minio:9000", public_host: "http://domain:9000")
        allow(SecureRandom).to receive(:uuid).and_return("1234")
        allow(Settings).to receive(:encoding).and_return(double(engine_adapter: "pass_through"))
      end

      it 'download the input first' do
        expect(described_class.engine_adapter).to receive(:create).with(altered_input, hash_including(outputs: [{ label: "high", url: altered_output }])).and_return(running_encode)
        encode.create!
        expect(File.exist?(altered_input)).to eq true
        expect(File.exist?(altered_output)).to eq true
      end
    end
  end
end
