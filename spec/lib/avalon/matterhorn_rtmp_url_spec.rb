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
require 'avalon/matterhorn_rtmp_url'

describe Avalon::MatterhornRtmpUrl do
  subject {Avalon::MatterhornRtmpUrl.parse('rtmp://localhost/avalon/mp4:98285a5b-603a-4a14-acc0-20e37a3514bb/b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3/MVI_0057.mp4')}

  describe '#application' do
    subject { super().application }
    it {is_expected.to eq('avalon')}
  end

  describe '#prefix' do
    subject { super().prefix }
    it {is_expected.to eq('mp4')}
  end

  describe '#media_id' do
    subject { super().media_id }
    it {is_expected.to eq('98285a5b-603a-4a14-acc0-20e37a3514bb')}
  end

  describe '#stream_id' do
    subject { super().stream_id }
    it {is_expected.to eq('b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3')}
  end

  describe '#filename' do
    subject { super().filename }
    it {is_expected.to eq('MVI_0057')}
  end

  describe '#extension' do
    subject { super().extension }
    it {is_expected.to eq('mp4')}
  end

  describe '#to_path' do
    subject { super().to_path }
    it {is_expected.to eq('98285a5b-603a-4a14-acc0-20e37a3514bb/b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3/MVI_0057.mp4')}
  end
end 
