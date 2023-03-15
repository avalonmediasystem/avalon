# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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
require 'avalon/controlled_vocabulary'

describe Avalon::ControlledVocabulary do
  before do
    allow(File).to receive(:read).and_return ''
    allow(File).to receive(:file?).and_return true
  end

  describe '#vocabulary' do
    it 'reads the file directly from disk' do
      expect(File).to receive(:read).twice
      Avalon::ControlledVocabulary.vocabulary
      Avalon::ControlledVocabulary.vocabulary
    end

    it 'returns an empty hash when yaml file is empty' do
      expect(Avalon::ControlledVocabulary.vocabulary).to eql({})
    end
  end

  describe '#find_by_name' do
    before do
      allow(Avalon::ControlledVocabulary).to receive(:vocabulary).and_return({ units: ['Default Unit', 'Archives'] })
    end

    it 'finds a vocabulary by name' do
      expect(Avalon::ControlledVocabulary.find_by_name('units')).to eql ['Default Unit', 'Archives']
    end

    it 'finds a vocabulary by symbol' do
      expect(Avalon::ControlledVocabulary.find_by_name(:units)).to eql ['Default Unit', 'Archives']
    end

    it 'finds and sorts the vocabulary' do
      expect(Avalon::ControlledVocabulary.find_by_name(:units, sort: true)).to eql ['Archives', 'Default Unit']
    end

    it 'finds and does not sort the vocabulary' do
      expect(Avalon::ControlledVocabulary.find_by_name(:units, sort: false)).to eql ['Default Unit', 'Archives']
    end
  end
end
