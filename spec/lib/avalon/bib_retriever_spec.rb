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
require 'avalon/bib_retriever'

describe Avalon::BibRetriever do
  let(:bib_id) { 7041954 }
  let(:mods) { File.read(File.expand_path("../../../fixtures/#{bib_id}.mods",__FILE__)) }
  
  describe 'sru' do
    before :each do
      Avalon::Configuration['bib_retriever'] = { 'protocol' => 'sru', 'url' => 'http://zgate.example.edu:9000/db' }
    end
    
    let(:sru_url) { "http://zgate.example.edu:9000/db?version=1.1&operation=searchRetrieve&maximumRecords=10000&recordSchema=marcxml&query=rec.id=#{bib_id}" }
    let(:sru_response) { File.read(File.expand_path("../../../fixtures/#{bib_id}.xml",__FILE__)) }
    it 'retrieves proper MODS' do
      RestClient.should_receive(:get).with(sru_url).and_return(sru_response)
      response = Avalon::BibRetriever.instance.get_record(bib_id)
      expect(Nokogiri::XML(response)).to be_equivalent_to(mods)
    end
  end
  
  describe 'zoom' do
    it 'retrieves proper MODS' do
      pending "need a reasonable way to mock ruby-zoom"
    end
  end
end
