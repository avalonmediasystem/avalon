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

require 'avalon/file_resolver'

describe Avalon::FileResolver do
  let(:resolver){ Avalon::FileResolver.new }
  describe "#path_to" do
    it 'returns umodified path when string already has a schema' do
      resolver.path_to('http://example.com').should == 'http://example.com'
    end
    it 'returns path with schema' do
      resolver.stub(:mount_map).and_return({'/Volumes/dropbox/'=> 'smb://example.edu/dropbox'})
      resolver.path_to('/Volumes/dropbox/master_files/').should == 'smb://example.edu/dropbox/master_files'
    end
    it 'returns path with file schema when no mounts match' do
      resolver.stub(:mount_map).and_return({})
      resolver.path_to('/storage/master_files/').should == 'file:///storage/master_files/'
    end
  end

  describe "#mount_map" do
    it 'returns a formatted mount' do
      resolver.stub(:overrides).and_return({})
      resolver.instance_variable_set(:@mounts, ['//adam@example.edu/dropbox on /Volumes/dropbox (smbfs, nodev, nosuid, mounted by adam)'])
      resolver.mount_map.should == {'/Volumes/dropbox/'=>'smb://example.edu/dropbox'}
    end
  end
end
