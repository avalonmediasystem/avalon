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
require 'avalon/ffprobe'

describe Avalon::FFprobe do
  subject { described_class.new(test_file) }

  let(:video_file) { FileLocator.new(Rails.root.join('spec', 'fixtures', 'videoshort.mp4').to_s) }
  let(:audioless_video_file) { FileLocator.new(Rails.root.join('spec', 'fixtures', 'videoshort_no_audio.mp4').to_s) }
  let(:audio_file) { FileLocator.new(Rails.root.join('spec', 'fixtures', 'jazz-performance.mp4').to_s) }
  let(:image_file) { FileLocator.new(Rails.root.join('spec', 'fixtures', 'collection_poster.png').to_s) }
  let(:text_file) { FileLocator.new(Rails.root.join('spec', 'fixtures', 'chunk_test.txt').to_s) }

  describe 'error handling' do
    let(:test_file) { video_file }

    it 'logs an error if ffprobe is misconfigured' do
      allow(Settings.ffprobe).to receive(:path).and_return('misconfigured/path')
      expect(Rails.logger).to receive(:error)
      subject.json_output
    end
  end

  describe '#video?' do
    context 'with a video file' do
      let(:test_file) { video_file }

      it 'returns true' do
        expect(subject.video?).to be true
      end
    end

    context "with an audio file" do
      let(:test_file) { audio_file }

      it 'returns false' do
        expect(subject.video?).to be false
      end
    end

    context 'with non-media files' do
      let(:text_test) { described_class.new(text_file) }
      let(:image_test) { described_class.new(image_file) }

      it 'returns false' do
        expect(text_test.video?).to be false
        expect(image_test.video?).to be false
      end
    end
  end

  describe '#audio?' do
    context 'with a video file that has an audio track' do
      let(:test_file) { video_file }

      it 'returns true' do
        expect(subject.audio?).to be true
      end
    end

    context 'with a video file that lacks an audio track' do
      let(:test_file) { audioless_video_file }

      it 'returns false' do
        expect(subject.audio?).to be false
      end
    end

    context "with an audio file" do
      let(:test_file) { audio_file }

      it 'returns true' do
        expect(subject.audio?).to be true
      end
    end

    context 'with non-media files' do
      let(:text_test) { described_class.new(text_file) }
      let(:image_test) { described_class.new(image_file) }

      it 'returns false' do
        expect(text_test.audio?).to be false
        expect(image_test.audio?).to be false
      end
    end
  end

  describe '#duration' do
    let(:test_file) { video_file }

    it 'returns correct value in milliseconds' do
      expect(subject.duration).to eq 6314
    end

    context 'with non-media files' do
      let(:text_test) { described_class.new(text_file) }
      let(:image_test) { described_class.new(image_file) }

      it 'returns nil' do
        expect(text_test.duration).to be nil
        expect(image_test.duration).to be nil
      end
    end
  end

  describe '#display_aspect_ratio' do
    context 'with video' do
      let(:test_file) { video_file }

      it 'returns the display aspect ratio' do
        expect(subject.display_aspect_ratio).to be_a(String)
        expect(subject.display_aspect_ratio).to eq '20:11'
      end

      context 'file missing display aspect ratio' do
        it 'calculates the display aspect ratio' do
          subject.instance_variable_set(:@video_stream, subject.video_stream.except!(:display_aspect_ratio))
          expect(subject.display_aspect_ratio).to be_a(String)
          expect(subject.display_aspect_ratio).to eq((200.to_f / 110.to_f).to_s)
        end
      end
    end

    context 'with audio' do
      let(:test_file) { audio_file }
      it 'returns nil' do
        expect(subject.display_aspect_ratio).to be nil
      end
    end

    context 'with non-media files' do
      let(:text_test) { described_class.new(text_file) }
      let(:image_test) { described_class.new(image_file) }

      it 'returns nil' do
        expect(text_test.display_aspect_ratio).to be nil
        expect(image_test.display_aspect_ratio).to be nil
      end
    end
  end

  describe '#original_frame_size' do
    context 'with video' do
      let(:test_file) { video_file }

      it 'returns the original frame size' do
        expect(subject.original_frame_size).to eq '200x110'
      end
    end

    context 'with audio' do
      let(:test_file) { audio_file }

      it 'returns nil' do
        expect(subject.original_frame_size).to be nil
      end
    end

    context 'with non-media files' do
      let(:text_test) { described_class.new(text_file) }
      let(:image_test) { described_class.new(image_file) }

      it 'returns nil' do
        expect(text_test.original_frame_size).to be nil
        expect(image_test.original_frame_size).to be nil
      end
    end
  end
end
