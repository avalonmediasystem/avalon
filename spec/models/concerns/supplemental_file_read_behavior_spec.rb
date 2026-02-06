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

describe SupplementalFileReadBehavior do
  describe '#supplemental_files' do
    let(:object) { FactoryBot.create(:master_file, supplemental_files_json: supplemental_files_json) }
    let(:transcript_file) { FactoryBot.create(:supplemental_file, :with_transcript_tag, :with_transcript_file) }
    let(:private_file) { FactoryBot.create(:supplemental_file, :with_transcript_file, tags: ['transcript', 'private']) }
    let(:supplemental_files) { [transcript_file, private_file] }
    let(:supplemental_files_json) { supplemental_files.map(&:to_global_id).map(&:to_s).to_s }

    context '"include_private: false"' do
      it 'returns only public supplemental files' do
        expect(object.supplemental_files(tag: 'transcript')).to eq [transcript_file]
      end
    end

    context '"include_private: true"' do
      it 'return all supplemental files with requested tag' do
        expect(object.supplemental_files(tag: 'transcript', include_private: true)).to eq supplemental_files
      end
    end
  end
end
