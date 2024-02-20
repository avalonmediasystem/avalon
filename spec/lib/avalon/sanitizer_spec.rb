# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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
require 'avalon/sanitizer'

describe Avalon::Sanitizer do
  describe '#sanitize' do
    it 'replaces blacklisted characters' do
      expect(Avalon::Sanitizer.sanitize('abcdefg&',['&','_'])).to eq('abcdefg_')
    end

    it 'replaces multiple blacklisted characters' do
      expect(Avalon::Sanitizer.sanitize('avalon*media&system',['*&','__'])).to eq('avalon_media_system')
    end

    it 'does not modify a string without any blacklisted characters' do
      expect(Avalon::Sanitizer.sanitize('avalon_media_system',['*&','__'])).to eq('avalon_media_system')
    end
  end
end
