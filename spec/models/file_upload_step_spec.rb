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

describe FileUploadStep do
  describe '#update_master_files' do
    let!(:master_file) {FactoryBot.create(:master_file, title: 'foo')}
    let!(:media_object) {FactoryBot.create(:media_object, master_files: [master_file])}
    it 'should not regenerate a section permalink when the title is changed' do
      step_context = {media_object: media_object, master_files: {master_file.id => {title: 'new title'}}}
      expect{FileUploadStep.new.update_master_files(step_context)}.to_not change{master_file.permalink}
    end
    it 'should be able to set a blank title' do
      step_context = {media_object: media_object, master_files: {master_file.id => {title: ''}}}
      FileUploadStep.new.update_master_files(step_context)
      expect(master_file.reload.title).to be_empty
    end
  end
end
