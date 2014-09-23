# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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
    let(:masterfile) {FactoryGirl.create(:master_file)}
    let(:mediaobject) {FactoryGirl.create(:media_object, parts: [masterfile])}
    let(:step_context) { {mediaobject: mediaobject, parts: {masterfile.pid => {label: 'new label'}}} }
    it 'should not regenerate a section permalink when the label is changed' do
      expect(masterfile).to_not receive(:permalink=)
      expect{FileUploadStep.new.update_master_files(step_context)}.to_not change{masterfile.permalink}
    end
  end
end
