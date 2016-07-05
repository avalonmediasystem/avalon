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

describe AvalonMarkerController do

  let(:master_file) { FactoryGirl.create(:master_file_with_derivative) }
  let(:avalon_clip) { FactoryGirl.create(:avalon_clip, master_file: master_file) }
  let(:user) { FactoryGirl.create(:user) }
  let(:playlist) { FactoryGirl.create(:playlist, user: user) }
  let(:playlist_item) { FactoryGirl.create(:playlist_item, playlist: playlist, clip: avalon_clip) }
  let(:avalon_marker) { FactoryGirl.create(:avalon_marker, playlist_item: playlist_item, master_file: master_file) }

  before :all do
    @controller = AvalonMarkerController.new
  end

  describe 'creating a marker and displaying it' do
    it 'can create a marker and display it as JSON' do
      allow(MasterFile).to receive(:find).and_return(master_file)
      post 'create', marker:{ master_file_id: master_file.id, playlist_item_id: playlist_item.id }
      expect { JSON.parse(response.body) }.not_to raise_error
    end
    it 'returns an error when the master file is not supplied' do
      expect(post 'create', marker:{ playlist_item_id: playlist_item.id } ).to have_http_status(400)
    end
    it 'returns an error when the master file cannot be found' do
      expect(post 'create', amarker:{ master_file_id: 'OC', playlist_item_id: playlist_item.id }).to have_http_status(400)
    end
    it 'returns an error when the playlist item is not supplied' do
      expect(post 'create', marker:{ master_file_id: master_file.id }).to have_http_status(400)
    end
    it 'returns an error when the playlist item cannot be found' do
      expect(post 'create', marker:{ master_file_id: master_file.id, playlist_item_id: 'OC' }).to have_http_status(400)
    end
  end
  describe 'updating a marker' do
    it 'can update a marker and display it as JSON' do
      avalon_marker.save!
      put 'update', id: avalon_marker.id, avalon_marker:{start_time: '60', title: '30 Seconds of Fun'}
      expect { JSON.parse(response.body) }.not_to raise_error
    end
    it 'raises an error when the marker cannot be found' do
      expect { put 'update', id: 'OC' }.to raise_error(ActionController::RoutingError, 'Marker Not Found')
    end
  end

  describe 'destroying a marker' do
    it 'can destroy a marker and returns the result as JSON' do
      avalon_marker.save!
      delete 'destroy', id: avalon_marker.id
      resp = JSON.parse(response.body)
      expect(resp['action']).to match('destroy')
      expect(resp['id']).to match(avalon_marker.id)
      expect(resp['success']).to be_truthy
    end
    it 'raises an error when the marker is not found to destroy' do
      expect { delete 'destroy', id: 'OC' }.to raise_error(ActionController::RoutingError, 'Marker Not Found')
    end
  end

  describe 'selected key updates' do
    it 'updates multiple fields' do
      avalon_marker.save!
      @controller.stub(:params).and_return(id: avalon_marker.id, 'avalon_marker'=>{start_time: '17', title: 'Detroit'})
      @controller.lookup_marker
      expect(@controller.instance_variable_get(:@marker)).to receive(:update).once
      expect { @controller.selected_key_updates }.not_to raise_error
    end
    it 'does not update the marker when no valid keys are passed' do
      avalon_marker.save!
      @controller.stub(:params).and_return(id: avalon_marker.id, 'avalon_marker'=>{s_time: '17', name: 'Detroit', stuff: 'The founding'})
      @controller.lookup_marker
      expect(@controller.instance_variable_get(:@marker)).not_to receive(:update)
      expect { @controller.selected_key_updates }.not_to raise_error
    end
  end
  describe 'looking up markers' do
    it 'raises an error when it cannot find a marker' do
      @controller.stub(:params).and_return(id: '1817')
      expect { @controller.lookup_marker }.to raise_error
    end
    it 'sets the marker class variable when it finds a marker' do
      avalon_marker.save!
      @controller.stub(:params).and_return(id: avalon_marker.id)
      expect { @controller.lookup_marker }.not_to raise_error
    end
  end
  describe 'raising errors' do
    it 'raises ActionController::RoutingError referencing marker by default' do
      expect { @controller.not_found }.to raise_error(ActionController::RoutingError, 'Marker Not Found')
    end
    it 'raises ActionController::RoutingError referencing marker when passed :marker' do
      expect { @controller.not_found(item: :marker) }.to raise_error(ActionController::RoutingError, 'Marker Not Found')
    end
    it 'raises ActionController::RoutingError referencing master_file when passed :master_file' do
      expect { @controller.not_found(item: :master_file) }.to raise_error(ActionController::RoutingError, 'Master File Not Found')
    end
  end
end
