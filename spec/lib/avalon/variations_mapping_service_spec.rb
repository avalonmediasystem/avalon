# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

require 'spec_helper'
require 'avalon/variations_mapping_service'

describe Avalon::VariationsMappingService do
  before(:all) do
    Avalon::Configuration['variations'] = { 'media_object_id_map_file' => 'spec/fixtures/variations_playlists/variations_media_object_id_map.yml' }
    Avalon::VariationsMappingService::MEDIA_OBJECT_ID_MAP = YAML.load_file(Avalon::Configuration['variations']['media_object_id_map_file']).freeze rescue {}
  end
  subject { Avalon::VariationsMappingService.new }

  describe '#find_master_file' do
    context 'with a matching master file' do
      let(:master_file) { FactoryGirl.create(:master_file) }
      before do
        master_file.DC.identifier += ['ADU7077A']
        master_file.save!
      end

      it 'returns the matching MasterFile' do
        expect(subject.find_master_file('IU/MediaObject/18451')).to eq master_file
      end
    end

    it 'raises an ArgumentError if the id is invalid' do
      expect { subject.find_master_file('EXAMPLE/Container/12345') }.to raise_error(ArgumentError)
    end
    it 'raises an Error if the id is not in the map' do
      expect { subject.find_master_file('EXAMPLE/MediaObject/badid') }.to raise_error(RuntimeError)
    end
    it 'raises an Error if no matching MasterFile can be found' do
      expect { subject.find_master_file('IU/MediaObject/8733') }.to raise_error(RuntimeError)
    end
  end
end
