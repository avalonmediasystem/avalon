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

require 'rails_helper'

describe 'StringAdditions' do
  describe 'remove_zero_width_chars' do
    it 'removes zero-width characters from the beginning and end of strings' do
      String::ZERO_WIDTH_CHARS.each do |char|
        expect("test#{char}".remove_zero_width_chars).to eq 'test'
        expect("#{char}test".remove_zero_width_chars).to eq 'test'
      end
    end

    it 'does not remove zero-width characters from the middle of strings' do
      String::ZERO_WIDTH_CHARS.each do |char|
        expect("test#{char}test".remove_zero_width_chars).to eq "test#{char}test"
        expect("#{char}test#{char}test#{char}".remove_zero_width_chars).to eq "test#{char}test"
      end
    end

    it 'does not remove non-zero-width characters' do
      expect('test'.remove_zero_width_chars).to eq 'test'
      expect('test '.remove_zero_width_chars).to eq 'test '
      expect(' test '.remove_zero_width_chars).to eq ' test '
      expect('test test'.remove_zero_width_chars).to eq 'test test'
      expect("\ttest\t".remove_zero_width_chars).to eq "\ttest\t"
      expect("\ntest\n".remove_zero_width_chars).to eq "\ntest\n"
    end
  end
end
