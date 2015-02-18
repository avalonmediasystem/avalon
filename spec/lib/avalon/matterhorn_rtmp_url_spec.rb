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

  its(:application) {should == 'avalon'}
  its(:prefix) {should == 'mp4'}
  its(:media_id) {should == '98285a5b-603a-4a14-acc0-20e37a3514bb'}
  its(:stream_id) {should == 'b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3'}
  its(:filename) {should == 'MVI_0057'}
  its(:extension) {should == 'mp4'}
  its(:to_path) {should == '98285a5b-603a-4a14-acc0-20e37a3514bb/b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3/MVI_0057.mp4'}
end 
