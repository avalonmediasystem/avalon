# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

describe DropboxController do
  before do

    # there is no easy way to build objects because of the way roles are set up
    # therefore this test could fail in the future if the archivist role doesn't
    # have the group admin_policy_object_editor. roles should be refactored into
    # a database backed model SOON so testing of permissions/abilities is more granular

    login_as :administrator
    @collection = FactoryBot.create(:collection)
    @temp_files = (0..20).map{|index| { name: "a_movie_#{index}.mov" } }
    @dropbox = double(Avalon::Dropbox)
    allow(@dropbox).to receive(:all).and_return @temp_files
    allow(Avalon::Dropbox).to receive(:new).and_return(@dropbox)
  end

  it 'deletes video/audio files' do
    expect(@dropbox).to receive(:delete).exactly(@temp_files.count).times
    delete :bulk_delete, params: { :collection_id => @collection.id, :filenames => @temp_files.map{|f| f[:name] } }
  end

  it "should allow the collection manager to delete" do
    login_user @collection.managers.first
    expect(@dropbox).to receive(:delete).exactly(@temp_files.count).times
    delete :bulk_delete, params: { :collection_id => @collection.id, :filenames => @temp_files.map{|f| f[:name]} }
    expect(response.status).to be(200)
  end

  [:group_manager, :student].each do |group|
    it "should not allow #{group} to delete" do
      login_as group
      delete :bulk_delete, params: { :collection_id => @collection.id, :filenames => @temp_files.map{|f| f[:name]} }
      expect(response).to render_template('errors/restricted_pid')
    end
  end
end
