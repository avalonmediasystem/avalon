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

describe CleanupWorkingFileJob do
  let(:working_file) { '/temp/working_file.mp4' }
  let(:master_file) { FactoryBot.build(:master_file, working_file_path: [working_file]) }

  before do
    allow(MasterFile).to receive(:find).and_return(master_file)
    allow(File).to receive(:exist?).and_return(true)
    allow(Dir).to receive(:exist?).and_return(true)
  end

  describe "perform" do
    it 'calls file delete when there is file to cleanup' do
      expect(File).to receive(:delete).with(working_file).once
      expect(Dir).to receive(:delete).with(File.dirname(working_file)).once
      CleanupWorkingFileJob.perform_now('abc123', [working_file])
    end
  end
end
