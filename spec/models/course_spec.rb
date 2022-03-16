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

describe Course do
  let(:first_media_object) { FactoryBot.create(:media_object) }
  let(:second_media_object) { FactoryBot.create(:media_object) }

  before :each do
    first_media_object.read_groups += ['english_101', 'sociology_101', 'underwater_basketweaving_302']
    second_media_object.read_groups += ['english_101', 'sociology_101', 'underwater_basketweaving_302']
    first_media_object.save
    second_media_object.save
    first_media_object.reload
    second_media_object.reload
  end

  it 'removes a course from multiple media objects' do
    Course.unlink_all('english_101')
    expect(first_media_object.reload.read_groups).not_to include('english_101')
    expect(second_media_object.reload.read_groups).not_to include('english_101')
  end

  it 'does not remove courses not specified' do
    Course.unlink_all('english_101')
    first_media_object.reload
    expect(first_media_object.read_groups).to include('sociology_101')
    expect(first_media_object.read_groups).to include('underwater_basketweaving_302')
  end
end
