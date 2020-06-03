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

require 'rails_helper'

describe 'StringAdditions' do
  describe 'remove_zero_width_chars' do
    it 'removes zero-width characters from the beginning and end of strings' do
      expect("test\u200B".remove_zero_width_chars).to eq 'test'
      expect("\u200Btest".remove_zero_width_chars).to eq 'test'
      expect("\u200Btest\u200Btest\u200B".remove_zero_width_chars).to eq "test\u200Btest"
      expect("test\u200D".remove_zero_width_chars).to eq 'test'
      expect("\u200Dtest".remove_zero_width_chars).to eq 'test'
      expect("\u200Dtest\u200Dtest\u200D".remove_zero_width_chars).to eq "test\u200Dtest"
      expect("test\u200C".remove_zero_width_chars).to eq 'test'
      expect("\u200Ctest".remove_zero_width_chars).to eq 'test'
      expect("\u200Ctest\u200Ctest\u200C".remove_zero_width_chars).to eq "test\u200Ctest"
      expect("test\uFEFF".remove_zero_width_chars).to eq 'test'
      expect("\uFEFFtest".remove_zero_width_chars).to eq 'test'
      expect("\uFEFFtest\uFEFFtest\uFEFF".remove_zero_width_chars).to eq "test\uFEFFtest"
      expect("test\u2060".remove_zero_width_chars).to eq 'test'
      expect("\u2060test".remove_zero_width_chars).to eq 'test'
      expect("\u2060test\u2060test\u2060".remove_zero_width_chars).to eq "test\u2060test"
    end

    it 'does not remove zero-width characters from the middle of strings' do
      expect("test\u200Btest".remove_zero_width_chars).to eq "test\u200Btest"
      expect("\u200Btest\u200Btest\u200B".remove_zero_width_chars).to eq "test\u200Btest"
      expect("test\u200Dtest".remove_zero_width_chars).to eq "test\u200Dtest"
      expect("\u200Dtest\u200Dtest\u200D".remove_zero_width_chars).to eq "test\u200Dtest"
      expect("test\u200Ctest".remove_zero_width_chars).to eq "test\u200Ctest"
      expect("\u200Ctest\u200Ctest\u200C".remove_zero_width_chars).to eq "test\u200Ctest"
      expect("test\uFEFFtest".remove_zero_width_chars).to eq "test\uFEFFtest"
      expect("\uFEFFtest\uFEFFtest\uFEFF".remove_zero_width_chars).to eq "test\uFEFFtest"
      expect("test\u2060test".remove_zero_width_chars).to eq "test\u2060test"
      expect("\u2060test\u2060test\u2060".remove_zero_width_chars).to eq "test\u2060test"
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