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

describe FedoraMigrate::MediaObject::ObjectMover do
  let(:media_object) { FactoryBot.create(:media_object, :with_master_file, :with_completed_workflow) }
  describe 'empty?' do
    it 'returns true when the media object has been wiped' do
      described_class.wipeout!(media_object)
      expect(described_class.empty?(media_object)).to be_truthy
    end
    it 'returns false if the media object has any information' do
      expect(described_class.empty?(media_object)).to be_falsey
    end
  end
  describe 'wipeout!' do
    it 'wipes all of the data' do
      resources = [:resource, :access_control, :descMetadata, :workflow, :master_files]
      resources.each do |res|
        expect(media_object.send(res).blank?).to be_falsey
      end
      expect(media_object.ordered_master_files.to_a.blank?).to be_falsey
      expect(described_class.empty?(media_object)).to be_falsey
      described_class.wipeout!(media_object)
      resources.each do |res|
        expect(media_object.send(res).blank?).to be_truthy
      end
      expect(media_object.ordered_master_files.to_a.blank?).to be_truthy
      expect(described_class.empty?(media_object)).to be_truthy
    end
  end
end
