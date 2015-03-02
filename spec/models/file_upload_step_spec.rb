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

describe FileUploadStep do
  describe '#update_master_files' do
    let!(:masterfile) {FactoryGirl.create(:master_file, label: 'foo')}
    let!(:mediaobject) {FactoryGirl.create(:media_object, parts: [masterfile])}
    it 'should not regenerate a section permalink when the label is changed' do
      step_context = {mediaobject: mediaobject, parts: {masterfile.pid => {label: 'new label'}}}
      expect{FileUploadStep.new.update_master_files(step_context)}.to_not change{masterfile.permalink}
    end
    it 'should be able to set a blank label' do
      step_context = {mediaobject: mediaobject, parts: {masterfile.pid => {label: ''}}}
      FileUploadStep.new.update_master_files(step_context)
      expect(masterfile.reload.label).to be_nil
    end
  end
end
