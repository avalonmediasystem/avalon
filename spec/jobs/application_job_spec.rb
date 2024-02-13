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

describe ApplicationJob do
  describe 'exception handling' do
    it 'rescues Ldp::Gone errors' do
      allow_any_instance_of(described_class).to receive(:perform).and_raise(Ldp::Gone)
      allow_any_instance_of(Exception).to receive(:backtrace).and_return(["Test trace"])
      expect(Rails.logger).to receive(:error).with('Ldp::Gone\nTest trace')
      expect { described_class.perform_now }.to_not raise_error
    end
  end
end
