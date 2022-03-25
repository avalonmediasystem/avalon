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

require 'avalon/build_utils'

describe Avalon::BuildUtils do
    before :all  do
      Utils = Avalon::BuildUtils.new
    end
  def get_contents_string(version)
    out = " some junk content\n"
    out += "  VERSION = '#{version}' \n"
    out += "blahblahblah \n"

  end
  def get_contents_array(version)
    contents_arr = []
    contents_arr.push "some junk content"
    contents_arr.push "VERSION = '#{version}'"
    contents_arr.push "blahblah"
  end

# TODO: ADD TESTS FOR READING CONFIG FILE

  describe '#detect_version' do
    it 'Detects 3 part version correctly with contents array' do
      version = "1.2.3"
      contents_arr = get_contents_array(version)

      expect(Utils.detect_version(contents_arr)).to eq('1.2.3')

    end

    it 'Detects 3 part version correctly with contents string' do
      version = "1.2.3"
      contents_str = get_contents_string(version)
      #puts "#{contents_str}"
      expect(Utils.detect_version(contents_str)).to eq('1.2.3')
    end

    it 'Detects 4 part version correctly' do
      version = "1.2.3.4"
      contents_arr = get_contents_array(version)

      expect(Utils.detect_version(contents_arr)).to eq('1.2.3.4')

    end

    it 'Detects >4 part version correctly (not supported)' do
      version = "1.2.3.4.5"
      contents_arr = get_contents_array(version)

      expect(Utils.detect_version(contents_arr)).to eq('')

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

    describe '#get_tags' do
      it 'Outputs correct tags for a 3-part version and no additional tags' do
        version = "1.2.3"
        expect(Utils.get_tags(version)).to eq(["1.2.3"])
      end

      it 'SPLITS and outputs correct tags for a 3-part version and no additional tags' do
        version = "1.2.3"
        split = true
        expect(Utils.get_tags(version, split)).to eq(["1", "1.2", "1.2.3"])
      end

      it 'Outputs correct tags for a 3-part version and a branch tag' do
        version = "3.2.1"
        tag = "staging"
        split = false
        expect(Utils.get_tags(version, split, tag)).to eq(["3.2.1-staging", "staging"])
      end

      it 'SPLITS and Outputs correct tags for a 3-part version and a branch tag TOP LEVEL production branch' do
        version = "3.2.1"
        branch = "production"
        split = true
        top_level = true
        expect(Utils.get_tags(version, split, branch, top_level)).to eq(["3-production", "3.2-production", "3.2.1-production", "3", "3.2", "3.2.1", "production"])
      end

      it 'Outputs correct tags for a 3-part version and a branch tag TOP LEVEL production branch' do
        version = "3.2.1"
        branch = "production"
        split = false
        top_level = true
        expect(Utils.get_tags(version, split, branch, top_level)).to eq(["3.2.1-production", "3.2.1", "production"])
      end

      it 'SPLITS and outputs correct tags for a 3-part version and a branch tag' do
        version = "3.2.1"
        tag = "staging"
        split = true
        expect(Utils.get_tags(version, split, tag)).to eq(["3-staging", "3.2-staging", "3.2.1-staging", "staging"])
      end

      it 'SPLITS and Outputs correct tags for a 4-part version and several tags' do
        version = "1.2.3.4"
        branch = "develop"
        tags = "latest,testing_something"
        split = true
        top_level = false
        expect(Utils.get_tags(version, split, branch, top_level, tags)).to eq(["1-develop", "1.2-develop", "1.2.3-develop", "1.2.3.4-develop", "develop", "latest", "testing_something"])
      end

      it 'Outputs correct tags for a 4-part version and several tags' do
        version = "1.2.3.4"
        branch = "develop"
        tags = "latest,testing_something"
        split = false
        top_level = false
        expect(Utils.get_tags(version, split, branch, top_level, tags)).to eq(["1.2.3.4-develop", "develop", "latest", "testing_something"])
      end

      it 'SPLITS and Outputs correct CSV tags for a 4-part version and several tags' do
        version = "11.12.13"
        branch= "develop"
        tags = "latest,testing_something"
        split = true
        top_level = false
        expect(Utils.get_tags(version, split, branch, top_level, tags)).to eq(["11-develop", "11.12-develop", "11.12.13-develop", "develop", "latest", "testing_something"])
      end

      it 'Outputs correct CSV tags for a 4-part version and several tags' do
        version = "11.12.13"
        branch= "develop"
        tags = "latest,testing_something"
        split = false
        top_level = false
        expect(Utils.get_tags(version, split, branch, top_level, tags)).to eq(["11.12.13-develop", "develop", "latest", "testing_something"])
      end




    end

  end
end
