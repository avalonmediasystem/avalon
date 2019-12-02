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
      let(:altered_input) { "/tmp/random_uuid/sample.mp4" }
      let(:altered_output) { "/tmp/random_uuid/sample.high.mp4" }
      let(:running_encode) do
        described_class.new(altered_input, outputs: [{ label: "high", url: altered_output }]).tap do |e|
          e.id = SecureRandom.uuid
          e.state = :running
          e.created_at = Time.zone.now
          e.updated_at = Time.zone.now
        end
      end

      before do
        # Force AWS library to load local file before fakefs is activated
        FileLocator::S3File.new("s3://bucket/sample.mp4").object
        FakeFS.activate!
        Settings.minio = double("minio", endpoint: "http://minio:9000", public_host: "http://domain:9000")
        allow(SecureRandom).to receive(:uuid).and_return("random_uuid")
        allow(Settings).to receive(:encoding).and_return(double(engine_adapter: "pass_through"))
      end

      after do
        FakeFS.deactivate!
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
