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

describe ApplicationController do

  describe 'virtual groups' do
    let(:vgroups) {['vgroup1', 'vgroup2']}
    before do
      login_as 'student'
    end

    describe '#set_virtual_groups' do
      before do
        request.session[:virtual_groups] = vgroups
      end
      it "should set the current user's virtual groups" do
        controller.set_virtual_groups
        expect(controller.current_user.virtual_groups).to eq(vgroups)
      end
    end

    describe '#remember_virtual_groups' do
      before do
        controller.current_user.virtual_groups = vgroups
      end
      it "should store the current user's virtual groups in the session" do
        controller.remember_virtual_groups
        expect(request.session[:virtual_groups]).to eq(vgroups)
      end
      it "should not overwrite the value of virtual groups in the session" do
        new_vgroups = ["foo", "bar"]
        request.session[:virtual_groups] = new_vgroups
        controller.remember_virtual_groups
        expect(request.session[:virtual_groups]).to eq(new_vgroups)
      end
    end
  end
end
