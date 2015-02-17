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

describe 'PID Assignment' do
  let(:repo)      { ActiveFedora::Base.connection_for_pid(0) }
  let(:namespace) { Avalon::Configuration.lookup('fedora.namespace') }
  let(:pid)       { "#{namespace}:12345" }
  
  it "should assign a PID in the correct namespace" do
    expect(repo).to receive(:mint).with({ namespace: namespace }).and_return(pid)
    mo = MediaObject.new
    mo.send(:assign_pid)
    expect(mo.pid).to eq(pid)
  end
end
