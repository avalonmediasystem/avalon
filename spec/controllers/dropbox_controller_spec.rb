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

describe DropboxController do
  before do
    
    # there is no easy way to build objects because of the way roles are set up
    # therefore this test could fail in the future if the archivist role doesn't
    # have the group admin_policy_object_editor. roles should be refactored into
    # a database backed model SOON so testing of permissions/abilities is more granular

    login_as 'content_provider' 
    @temp_files = (0..20).map{|index| { name: "a_movie_#{index}.mov" } }
    Avalon::DropboxService.stub(:all).and_return @temp_files
  end

  it 'deletes video/audio files' do
    Avalon::DropboxService.should_receive(:delete).exactly(@temp_files.count).times
    delete :bulk_delete, { :filenames => @temp_files.map{|f| f[:name] } }
  end

end
