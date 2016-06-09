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

  it "should have attributes" do
    expect(subject.application).to eq('avalon')
    expect(subject.prefix).to eq('mp4')
    expect(subject.media_id).to eq('98285a5b-603a-4a14-acc0-20e37a3514bb')
    expect(subject.stream_id).to eq('b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3')
    expect(subject.filename).to eq('MVI_0057')
    expect(subject.extension).to eq('mp4')
    expect(subject.to_path).to eq('98285a5b-603a-4a14-acc0-20e37a3514bb/b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3/MVI_0057.mp4')
  end
end 
