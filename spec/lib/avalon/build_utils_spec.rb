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

#require 'rails_helper'
require 'avalon/build_utils'

#Utils = Avalon::AvalonVersionUtls.init

describe Avalon::BuildUtils do
    before :all  do
      Utils = Avalon::BuildUtils.new
    end
  def get_contents_string(version)
    out = "some junk content \
    VERSION = '#{version}' \
    blahblahblah \
    "
  end
  def get_contents_array(version)
    contents_arr = []
    contents_arr.push "some junk content"
    contents_arr.push "VERSION = '#{version}'"
    contents_arr.push "blahblah"
  end

# TODO: ADD TESTS FOR READING CONFIG FILE

  describe 'detect_version' do
    it 'Detects 3 part version correctly with contents array' do
      version = "1.2.3"
      contents_arr = get_contents_array(version)

      expect(Utils.detect_version(contents_arr)).to eq('1.2.3')

    end

    it 'Detects 3 part version correctly with contents string' do
      version = "1.2.3"
      contents_str = get_contents_string(version)
      expect(Utils.detect_version(contents_str)).to eq('1.2.3')
    end

    it 'Detects 4 part version correctly' do
      version = "1.2.3.4"
      contents_arr = get_contents_array(version)

      expect(Utils.detect_version(contents_arr)).to eq('1.2.3.4')

    end

    it 'Detects >4 part version correctly (not supported)' do
      version = "1.2.3.4.5.6"
      contents_arr = get_contents_array(version)

      expect(Utils.detect_version(contents_arr)).to eq('1.2.3.4')

    end

    it 'Detects 2 part version correctly (not supported)' do
      version = "1.2"
      contents_arr = get_contents_array(version)
      expect(Utils.detect_version(contents_arr)).to eq('')
    end

    it 'Detects 1 part version correctly (not supported)' do
      version = "1"
      contents_arr = get_contents_array(version)
      expect(Utils.detect_version(contents_arr)).to eq('')
    end

    it 'Ignores commented lines in config file contents' do
      version = "3.14.1"
      contents_arr = []
      contents_arr.push "# VERSION = '2.0.1'"
      contents_arr.concat get_contents_array(version)
      expect(Utils.detect_version(contents_arr)).to eq('3.14.1')
    end



    # it 'replaces multiple blacklisted characters' do
    #   expect(Avalon::Sanitizer.sanitize('avalon*media&system',['*&','__'])).to eq('avalon_media_system')
    # end
    #
    # it 'does not modify a string without any blacklisted characters' do
    #   expect(Avalon::Sanitizer.sanitize('avalon_media_system',['*&','__'])).to eq('avalon_media_system')
    # end
  end
end
