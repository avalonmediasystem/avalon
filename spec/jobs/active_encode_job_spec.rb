# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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

describe ActiveEncodeJob do
  describe ActiveEncodeJob::Create do
    let(:job) { ActiveEncodeJob::Create.new(master_file.id, nil, {}) }
    let(:master_file) { FactoryBot.create(:master_file) }

    describe "perform" do
      context "with error" do
        before do
          allow_any_instance_of(ActiveEncode::Base).to receive(:create!).and_raise(StandardError)
        end

        it "sets the status of the master file to FAILED" do
          job.perform(*job.arguments)
          master_file.reload
          expect(master_file.status_code).to eq('FAILED')
        end
      end

      context "with uncreated job" do
        before do
          allow(encode_job).to receive(:id).and_return(nil)
          allow_any_instance_of(ActiveEncode::Base).to receive(:create!).and_return(encode_job)
        end

        let(:encode_job) { ActiveEncode::Base.new(nil) }

        it "sets the status of the master file to FAILED" do
          job.perform(*job.arguments)
          master_file.reload
          expect(master_file.status_code).to eq('FAILED')
        end
      end
    end
  end
end
