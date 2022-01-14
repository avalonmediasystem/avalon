# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

describe FedoraMigrate::AdminCollection::ObjectMover do
  let(:collection) { FactoryBot.create(:collection) }
  describe 'empty?' do
    it 'returns true when the admin collection has been wiped' do
      described_class.wipeout!(collection)
      expect(described_class.empty?(collection)).to be_truthy
    end
    it 'returns false if the admin collection has any information' do
      expect(described_class.empty?(collection)).to be_falsey
    end
  end
  describe 'wipeout!' do
    it 'wipes all of the data' do
      resources = [:resource, :default_permissions, :access_control]
      resources.each do |res|
        expect(collection.send(res).blank?).to be_falsey
      end
      expect(described_class.empty?(collection)).to be_falsey
      described_class.wipeout!(collection)
      resources.each do |res|
        expect(collection.send(res).blank?).to be_truthy
      end
      expect(described_class.empty?(collection)).to be_truthy
    end
  end
end
