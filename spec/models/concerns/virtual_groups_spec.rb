# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

describe VirtualGroups do

  before(:all) do
    class Foo < ActiveFedora::Base
      include Hydra::AccessControls::Permissions
      include VirtualGroups
    end
  end
  after(:all) { Object.send(:remove_const, :Foo) }

  subject { Foo.new }

  describe 'virtual groups' do
    let!(:local_groups) {[FactoryBot.create(:group).name, FactoryBot.create(:group).name]}
    let(:virtual_groups) {["vgroup1", "vgroup2"]}
    let(:ip_groups) {[Faker::Internet.ip_v4_address, Faker::Internet.ip_v6_address, Faker::Internet.ip_v4_address + "/24"]}
    before(:each) do
      subject.read_groups = local_groups + virtual_groups + ip_groups
    end

    describe '#local_group_exceptions' do
      it 'should have only local groups' do
        expect(subject.local_read_groups).to eq(local_groups)
      end
    end

    describe '#virtual_group_exceptions' do
      it 'should have only non-local groups' do
        expect(subject.virtual_read_groups).to eq(virtual_groups)
      end
    end

    describe '#ip_group_exceptions' do
      it 'should have only ip groups' do
        expect(subject.ip_read_groups).to eq(ip_groups)
      end
    end
  end
end
