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

require 'avalon/build_utils'

describe Avalon::BuildUtils do
  subject(:utils) { described_class.new }

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

      expect(subject.detect_version(contents_arr)).to eq('1.2.3')

    end

    it 'Detects 3 part version correctly with contents string' do
      version = "1.2.3"
      contents_str = get_contents_string(version)
      expect(subject.detect_version(contents_str)).to eq('1.2.3')
    end

    it 'Detects 4 part version correctly' do
      version = "1.2.3.4"
      contents_arr = get_contents_array(version)

      expect(subject.detect_version(contents_arr)).to eq('1.2.3.4')

    end

    it 'Detects >4 part version correctly (not supported)' do
      version = "1.2.3.4.5"
      contents_arr = get_contents_array(version)

      expect(subject.detect_version(contents_arr)).to eq('')

    end

    it 'Detects 2 part version correctly (not supported)' do
      version = "1.2"
      contents_arr = get_contents_array(version)
      expect(subject.detect_version(contents_arr)).to eq('')
    end

    it 'Detects 1 part version correctly (not supported)' do
      version = "1"
      contents_arr = get_contents_array(version)
      expect(subject.detect_version(contents_arr)).to eq('')
    end

    it 'Ignores commented lines in config file contents' do
      version = "3.14.1"
      contents_arr = []
      contents_arr.push "# VERSION = '2.0.1'"
      contents_arr.concat get_contents_array(version)
      expect(subject.detect_version(contents_arr)).to eq('3.14.1')
    end

    describe '#get_tags' do
      it 'Returns an empty array if no branch nor top_level options' do
        version = "1.2.3"
        expect(subject.get_tags(version)).to eq([])
      end
      it 'Outputs correct tags for a 3-part version and top_level true' do
        version = "1.2.3"
        options = {"top_level": true}
        expect(subject.get_tags(version, options)).to eq("1.2.3")
      end

      it 'SPLITS and outputs correct tags for a 3-part version and no additional tags' do
        version = "1.2.3"
        options = {"top_level": true, "split": true}
        expect(subject.get_tags(version, options)).to eq("1,1.2,1.2.3")
      end

      it 'Outputs correct tags for a 3-part version and a branch tag' do
        version = "3.2.1"
        options = {"split": false, "branch": "staging"}
        expect(subject.get_tags(version, options)).to eq("3.2.1-staging,staging")
      end

      it 'SPLITS and Outputs correct tags for a 3-part version and a branch tag TOP LEVEL production branch' do
        version = "3.2.1"
        options = {"split": true, "branch": "production", "top_level": true}
        expect(subject.get_tags(version, options)).to eq("3,3-production,3.2,3.2-production,3.2.1,3.2.1-production,production")
      end

      it 'SPLITS and Outputs correct tags for a 3-part version and a branch tag NOT TOP LEVEL staging branch' do
        version = "3.2.1"
        options = {"split": true, "branch": "staging", "top_level": false}
        expect(subject.get_tags(version, options)).to eq("3-staging,3.2-staging,3.2.1-staging,staging")
      end

      it 'Outputs correct tags for a 3-part version and a branch tag TOP LEVEL production branch' do
        version = "3.2.1"
        branch = "production"
        options = {"split": false, "branch": "production", "top_level": true}
        expect(subject.get_tags(version, options)).to eq("3.2.1,3.2.1-production,production")
      end

      it 'SPLITS and Outputs correct tags for a 4-part version and several tags' do
        version = "1.2.3.4"
        options = {"split": true, "branch": "develop", "additional_tags": "latest,testing_something"}
        expect(subject.get_tags(version, options)).to eq("1-develop,1.2-develop,1.2.3-develop,1.2.3.4-develop,develop,latest,testing_something")
      end

      it 'Outputs correct tags for a 4-part version and several tags' do
        version = "1.2.3.4"
        options = {"split": false, "branch": "develop", "additional_tags": "latest,testing_something"}
        expect(subject.get_tags(version, options)).to eq("1.2.3.4-develop,develop,latest,testing_something")
      end

      it 'SPLITS and Outputs correct CSV tags for a 3-part version and several tags' do
        version = "11.12.13"
        options = {"split": true, "branch": "develop", "additional_tags": "latest,testing_something"}
        expect(subject.get_tags(version, options)).to eq("11-develop,11.12-develop,11.12.13-develop,develop,latest,testing_something")
      end

      it 'Outputs correct CSV tags for a 3-part version and several tags' do
        version = "11.12.13"
        options = {"split": false, "branch": "develop", "additional_tags": "latest,testing_something"}
        expect(subject.get_tags(version, options)).to eq("11.12.13-develop,develop,latest,testing_something")
      end

      it 'Avoids outputing duplicate tags' do
        version = "11.12.13"
        options = {"split": false, "branch": "develop", "additional_tags": "latest,test,develop"}
        expect(subject.get_tags(version, options)).to eq("11.12.13-develop,develop,latest,test")
      end
    end

  end
end
