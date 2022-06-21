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
    context 'with S3 inputs' do
      let!(:altered_input) { Tempfile.new("sample.mp4") }
      let!(:altered_output) { Tempfile.new("sample.high.mp4") }
      let(:running_encode) do
        described_class.new(altered_input.path, outputs: [{ label: "high", url: altered_output.path }]).tap do |e|
          e.id = SecureRandom.uuid
          e.state = :running
          e.created_at = Time.zone.now
          e.updated_at = Time.zone.now
        end
      end

      before do
        allow(Tempfile).to receive(:new).with("sample.mp4").and_return(altered_input)
        allow(Tempfile).to receive(:new).with("sample.high.mp4").and_return(altered_output)
        allow(Settings).to receive(:encoding).and_return(double(engine_adapter: "pass_through"))
      end

      it 'download the input first' do
        expect(described_class.engine_adapter).to receive(:create).with(altered_input.path, hash_including(outputs: [{ label: "high", url: altered_output.path }])).and_return(running_encode)
        encode.create!
        expect(File.exist?(altered_input.path)).to eq true
        expect(File.exist?(altered_output.path)).to eq true
      end
    end
  end
end
