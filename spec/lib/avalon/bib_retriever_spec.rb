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
require 'avalon/bib_retriever'

describe Avalon::BibRetriever do
  let(:bib_id) { '7763100' }
  let(:mods) { File.read(File.expand_path("../../../fixtures/#{bib_id}.mods",__FILE__)) }

  describe 'configured?' do
    before :each do
      Avalon::Configuration['bib_retriever'] = { 'protocol' => 'sru', 'url' => 'http://zgate.example.edu:9000/db' }
    end
    
    it 'valid' do
      expect(Avalon::BibRetriever).to be_configured
    end
    
    it 'invalid' do
      Avalon::Configuration['bib_retriever'] = { 'protocol' => 'unknown', 'url' => 'http://zgate.example.edu:9000/db' }
      expect(Avalon::BibRetriever).not_to be_configured
    end
    
    it 'missing' do
      Avalon::Configuration['bib_retriever'] = nil
      expect(Avalon::BibRetriever).not_to be_configured
    end
  end
  
  describe 'sru' do
    let(:sru_url) { "http://zgate.example.edu:9000/db?version=1.1&operation=searchRetrieve&maximumRecords=1&recordSchema=marcxml&query=rec.id=%5E%25#{bib_id}" }
    let(:sru_response) { File.read(File.expand_path("../../../fixtures/#{bib_id}.xml",__FILE__)) }

    before :each do
      Avalon::Configuration['bib_retriever'] = { 'protocol' => 'sru', 'url' => 'http://zgate.example.edu:9000/db' }
      FakeWeb.register_uri :get, sru_url, body: sru_response
    end
    
    after :each do
      FakeWeb.clean_registry
    end
    
    it 'retrieves proper MODS' do
      response = Avalon::BibRetriever.instance.get_record("^%#{bib_id}")
      expect(Nokogiri::XML(response)).to be_equivalent_to(mods)
    end
  end
  
  describe 'zoom' do
    it 'retrieves proper MODS' do
      pending "need a reasonable way to mock ruby-zoom"
    end
  end
end
