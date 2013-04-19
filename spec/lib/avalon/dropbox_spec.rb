# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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
require 'avalon/dropbox'


describe Avalon::Dropbox do

  describe "#delete" do

    it 'returns true if the file is found' do
      File.stub(:delete).and_return true
      Avalon::DropboxService.delete('some_file.mov')
    end

    it 'returns false if the file is not found' do
      Avalon::DropboxService.delete('some_file.mov').should be_false
    end

  end

end
