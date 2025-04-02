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
require 'avalon/bib_retriever'

describe Avalon::BibRetriever do
  let(:bib_id) { '7763100' }
  let(:mods) { File.read(File.expand_path("../../../fixtures/#{bib_id}.mods",__FILE__)) }

  describe 'configured?' do
    it 'valid' do
      expect(Avalon::BibRetriever).to be_configured
    end

    it 'invalid' do
      Settings.bib_retriever = { 'default' => { 'protocol' => 'unknown', 'url' => 'http://zgate.example.edu:9000/db' } }
      expect(Avalon::BibRetriever).not_to be_configured
    end

    it 'missing' do
      Settings.bib_retriever = nil
      expect(Avalon::BibRetriever).not_to be_configured
    end
  end

  describe 'sru' do
    let(:sru_url) { "http://zgate.example.edu:9000/db?version=1.1&operation=searchRetrieve&maximumRecords=1&recordSchema=marcxml&query=rec.id=%5E%25#{bib_id}" }

    describe 'default namespace' do
      let(:sru_response) { File.read(File.expand_path("../../../fixtures/#{bib_id}.xml",__FILE__)) }
      let!(:request) { stub_request(:get, sru_url).to_return(body: sru_response) }

      it 'retrieves proper MODS' do
        response = Avalon::BibRetriever.instance.get_record("^%#{bib_id}")
        expect(request).to have_been_requested
        expect(Nokogiri::XML(response)).to be_equivalent_to(mods)
      end
    end

    describe 'alternate namespace' do
      let(:sru_response) { File.read(File.expand_path("../../../fixtures/#{bib_id}-ns.xml",__FILE__)) }
      let!(:request) { stub_request(:get, sru_url).to_return(body: sru_response) }

      it 'retrieves proper MODS' do
        Settings.bib_retriever = { 'default' => { 'protocol' => 'sru', 'url' => 'http://zgate.example.edu:9000/db', 'namespace' => 'http://example.edu/fake/sru/namespace/', 'retriever_class' => 'Avalon::BibRetriever::SRU', 'retriever_class_require' => 'avalon/bib_retriever/sru' } }
        response = Avalon::BibRetriever.instance.get_record("^%#{bib_id}")
        expect(request).to have_been_requested
        expect(Nokogiri::XML(response)).to be_equivalent_to(mods)
      end
    end

    describe 'multiple configured queries' do
      let(:sru_url) { "http://zgate.example.edu:9000/db?version=1.1&operation=searchRetrieve&maximumRecords=1&recordSchema=marcxml&query=rec.id=%27not_a_real_id%27" }
      let(:sru_url_2) { "http://zgate.example.edu:9000/db?version=1.1&operation=searchRetrieve&maximumRecords=1&recordSchema=marcxml&query=cql.serverChoice=%27%5EC%5E%257763100%27" }
      let(:sru_response) { File.read(File.expand_path("../../../fixtures/#{bib_id}.xml",__FILE__)) }
      let!(:request) { stub_request(:get, sru_url).to_return(body: '') }
      let!(:request_2) { stub_request(:get, sru_url_2).to_return(body: sru_response) }

      it 'retrieves proper MODS' do
        Settings.bib_retriever = { 'default' => { 'protocol' => 'sru', 'url' => 'http://zgate.example.edu:9000/db', 'query' => ["rec.id='not_a_real_id'","cql.serverChoice='^C%{bib_id}'"], 'retriever_class' => 'Avalon::BibRetriever::SRU', 'retriever_class_require' => 'avalon/bib_retriever/sru' } }
        response = Avalon::BibRetriever.instance.get_record("^%#{bib_id}")
        expect(Nokogiri::XML(response)).to be_equivalent_to(mods)
        expect(request).to have_been_requested
        expect(request_2).to have_been_requested
      end
    end

  end

  describe 'zoom' do
    it 'retrieves proper MODS' do
      skip "need a reasonable way to mock ruby-zoom"
    end
  end
end
