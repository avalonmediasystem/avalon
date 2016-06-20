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

describe AvalonClipController do
  subject(:video_master_file) { FactoryGirl.create(:master_file_with_derivative) }
  let(:clip) { AvalonClip.new(master_file: video_master_file) }

  before :all do
    @controller = AvalonClipController.new
  end

  describe 'creating a clip and displaying it' do
    it 'can create a clip and display it as JSON' do
      allow(MasterFile).to receive(:find).and_return(video_master_file)
      post 'create', master_file: video_master_file.id
      expect { JSON.parse(response.body) }.not_to raise_error
    end
    it 'raises an ArgumentError error when the master file is not supplied' do
      expect { post 'create' }.to raise_error(ArgumentError, 'Master File Not Supplied')
    end
    it 'raises an error when the master fille cannot be found' do
      expect { post 'create', master_file: 'OC' }.to raise_error(ActionController::RoutingError, 'Master File Not Found')
    end
  end
  describe 'updating a clip' do
    it 'can update a clip and display it as JSON' do
      clip.save!
      put 'update', id: clip.uuid, start_time: '60', end_time: '90', title: '30 Seconds of Fun', comment: 'Are we having fun yet?'
      expect { JSON.parse(response.body) }.not_to raise_error
    end
    it 'raises an error when the clip cannot be found' do
      expect { put 'update', id: 'OC' }.to raise_error(ActionController::RoutingError, 'Clip Not Found')
    end
  end

  describe 'displaying a clip' do
    it 'can display a clip as JSON' do
      clip.save!
      get 'show', id: clip.uuid
      expect { JSON.parse(response.body) }.not_to raise_error
    end
    it 'raises an error when it cannot find the clip' do
      expect { get 'show', id: 'OC' }.to raise_error(ActionController::RoutingError, 'Clip Not Found')
    end
  end
  describe 'destroying a clip' do
    it 'can destroy a clip and returns the result as JSON' do
      clip.save!
      delete 'destroy', id: clip.uuid
      resp = JSON.parse(response.body)
      expect(resp['action']).to match('destroy')
      expect(resp['id']).to match(clip.uuid)
      expect(resp['success']).to be_truthy
    end
    it 'raises an error when the clip is not found to destroy' do
      expect { delete 'destroy', id: 'OC' }.to raise_error(ActionController::RoutingError, 'Clip Not Found')
    end
  end

  describe 'selected key updates' do
    it 'updates multiple fields' do
      clip.save!
      @controller.stub(:params).and_return(id: clip.uuid, start_time: '17', end_time: '17', title: 'Detroit', comment: 'The founding')
      @controller.lookup_clip
      expect(@controller.instance_variable_get(:@clip)).to receive(:update).once
      expect { @controller.selected_key_updates }.not_to raise_error
    end
    it 'does not update the clip when no valid keys are passed' do
      clip.save!
      @controller.stub(:params).and_return(id: clip.uuid, s_time: '17', e_time: '17', name: 'Detroit', stuff: 'The founding')
      @controller.lookup_clip
      expect(@controller.instance_variable_get(:@clip)).not_to receive(:update)
      expect { @controller.selected_key_updates }.not_to raise_error
    end
  end
  describe 'looking up clips' do
    it 'raises an error when it cannot find a clip' do
      @controller.stub(:params).and_return(id: '1817')
      expect { @controller.lookup_clip }.to raise_error
    end
    it 'sets the clip class variable when it finds a clip' do
      clip.save!
      @controller.stub(:params).and_return(id: clip.uuid)
      expect { @controller.lookup_clip }.not_to raise_error
    end
  end
  describe 'raising errors' do
    it 'raises ActionController::RoutingError referencing clip by default' do
      expect { @controller.not_found }.to raise_error(ActionController::RoutingError, 'Clip Not Found')
    end
    it 'raises ActionController::RoutingError referencing clip when passed :clip' do
      expect { @controller.not_found(item: :clip) }.to raise_error(ActionController::RoutingError, 'Clip Not Found')
    end
    it 'raises ActionController::RoutingError referencing master_file when passed :master_file' do
      expect { @controller.not_found(item: :master_file) }.to raise_error(ActionController::RoutingError, 'Master File Not Found')
    end
  end
end
