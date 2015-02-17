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
require 'avalon/controlled_vocabulary'

describe Avalon::ControlledVocabulary do
  before do
    File.stub(:read).and_return ''
    File.stub(:file?).and_return true
  end

  describe '#vocabulary' do 
    it 'reads the file directly from disk' do
      File.should_receive(:read).twice
      Avalon::ControlledVocabulary.vocabulary
      Avalon::ControlledVocabulary.vocabulary
    end

    it 'returns an empty hash when yaml file is empty' do
      Avalon::ControlledVocabulary.vocabulary.should eql({})
    end
  end

  describe '#find_by_name' do
    before do
      Avalon::ControlledVocabulary.stub(:vocabulary).and_return({ units: ['Archives'] })
    end

    it 'finds a vocabulary by name' do
      Avalon::ControlledVocabulary.find_by_name('units').should eql ['Archives']
    end

    it 'finds a vocabulary by symbol' do
      Avalon::ControlledVocabulary.find_by_name(:units).should eql ['Archives']
    end
  end

end
