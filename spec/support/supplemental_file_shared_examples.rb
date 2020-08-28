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

RSpec.shared_examples 'an object that has supplemental files' do
  let(:object) { FactoryBot.build(described_class.model_name.singular.to_sym) }
  let(:supplemental_file) { FactoryBot.create(:supplemental_file) }
  let(:supplemental_files) { [supplemental_file] }
  let(:supplemental_files_json) { [supplemental_file.to_global_id.to_s].to_json }

  context 'supplemental_files=' do
    it 'stores the supplemental files as a json string in a property' do
      expect { object.supplemental_files = supplemental_files }.to change { object.supplemental_files_json }.from(nil).to(supplemental_files_json)
    end
  end

  context 'supplemental_files' do
    let(:object) { FactoryBot.build(described_class.model_name.singular.to_sym, supplemental_files_json: supplemental_files_json) }

    it 'reifies the supplemental files from the stored json string' do
      expect(object.supplemental_files).to eq supplemental_files
    end
  end
end
