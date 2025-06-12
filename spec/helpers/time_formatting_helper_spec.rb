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

require 'rails_helper'

describe TimeFormattingHelper do
    describe "#milliseconds_to_formatted_time" do
    it "should return correct values" do
      expect(helper.milliseconds_to_formatted_time(0)).to eq("00:00")
      expect(helper.milliseconds_to_formatted_time(1000)).to eq("00:01")
      expect(helper.milliseconds_to_formatted_time(60000)).to eq("01:00")
      expect(helper.milliseconds_to_formatted_time(3600000)).to eq("1:00:00")
      expect(helper.milliseconds_to_formatted_time(1123)).to eq("00:01.123")
      expect(helper.milliseconds_to_formatted_time(1123, false)).to eq("00:01")
    end
  end

  describe "#pretty_time" do
    it 'returns a formatted time' do
      expect(helper.pretty_time(0)).to eq '00:00:00.000'
      expect(helper.pretty_time(1)).to eq '00:00:00.001'
      expect(helper.pretty_time(9)).to eq '00:00:00.009'
      expect(helper.pretty_time(10)).to eq '00:00:00.010'
      expect(helper.pretty_time(101)).to eq '00:00:00.101'
      expect(helper.pretty_time(1010)).to eq '00:00:01.010'
      expect(helper.pretty_time(10101)).to eq '00:00:10.101'
      expect(helper.pretty_time(101010)).to eq '00:01:41.010'
      expect(helper.pretty_time(1010101)).to eq '00:16:50.101'
      expect(helper.pretty_time(10101010)).to eq '02:48:21.010'
      expect(helper.pretty_time(0.0)).to eq '00:00:00.000'
      expect(helper.pretty_time(0.1)).to eq '00:00:00.000'
      expect(helper.pretty_time(1.1)).to eq '00:00:00.001'
      expect(helper.pretty_time(-1000)).to eq '00:00:00.000'
      expect(helper.pretty_time('0')).to eq '00:00:00.000'
      expect(helper.pretty_time('1')).to eq '00:00:00.001'
      expect(helper.pretty_time('10101010')).to eq '02:48:21.010'
      expect(helper.pretty_time('-1000')).to eq '00:00:00.000'
      expect(helper.pretty_time('0.0')).to eq '00:00:00.000'
      expect(helper.pretty_time('0.1')).to eq '00:00:00.000'
      expect(helper.pretty_time('1.1')).to eq '00:00:00.001'
    end

    it 'returns an exception when not a number' do
      expect { helper.pretty_time(nil) }.to raise_error(TypeError)
      expect { helper.pretty_time('foo') }.to raise_error(ArgumentError)
    end
  end
end
