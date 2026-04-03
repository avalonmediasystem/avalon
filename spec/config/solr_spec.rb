# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

describe 'Solr' do
  describe 'retry' do
    let!(:solr_conn) { ActiveFedora::SolrService.instance.conn }

    it 'should retry 503 errors' do
      WebMock.reset_executed_requests!
      expect(ActiveFedora.solr.options[:retry_503]).to eq true
      stub_request(:post, /#{ActiveFedora.solr.options[:url]}/).with(body: "q=*%3A*&qt=standard").to_raise(Errno::ECONNREFUSED) #to_return({status: 503}, {status: 200, body: ''})
      ActiveFedora::SolrService.query('*:*') rescue nil
      expect(a_request(:post, /#{ActiveFedora.solr.options[:url]}/).with(body: "q=*%3A*&qt=standard")).to have_been_made.times(3)
      WebMock.reset!
    end
  end
end
