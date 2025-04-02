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
require 'avalon/batch'


describe Avalon::Batch do
  describe "#find_open_files" do
    # TODO: mock filesystem with open file
    subject { Avalon::Batch.find_open_files([]) }
    xit 'returns open files' do
      expect(subject).to include()
    end

    context "too many arguments" do
      let(:file) { File.absolute_path("spec/fixtures/meow.wav") }
      let(:files) { Array.new(5000, file) }
      subject { Avalon::Batch.find_open_files(files) }

      xit 'logs an error and moves on' do
        expect(Rails.logger).to receive(:warn).with(match("too many files"))
        expect(subject).to include()
      end
    end
  end
end
