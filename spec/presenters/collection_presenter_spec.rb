# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

describe CollectionPresenter do
  let(:id) {  "abcd12345" }
  let(:name) { "Sample Collection" }
  let(:unit) { "Default Unit" }
  let(:description) { "The long form description of this collection." }
  let(:has_poster) { true }
  let(:website_label) { Faker::Lorem.words.join(' ') }
  let(:website_url) { Faker::Internet.url }
  let(:contact_email) { Faker::Internet.email }
  let(:website_link) { "<a href='#{website_label}'>#{website_url}</a>" }
  let(:solr_doc) do
    SolrDocument.new(
      id: id,
      "name_ssi": name,
      "unit_ssi": unit,
      "description_tesim": [description],
      "has_poster_bsi": has_poster,
      "website_label_ssi": website_label,
      "website_url_ssi": website_url,
      "contact_email_ssi": contact_email
    )
  end
  let(:view_context) { double('View Context', website_link: website_link) }
  subject(:presenter) { described_class.new(solr_doc, view_context) }

  before do
    allow(view_context).to receive(:link_to).with(website_label, website_url).and_return(website_link)
  end

  it 'provides getters for descriptive fields' do
    expect(presenter.id).to eq id
    expect(presenter.name).to eq name
    expect(presenter.unit).to eq unit
    expect(presenter.description).to eq description
    expect(presenter.contact_email).to eq contact_email
    expect(presenter.website_link).to eq website_link
  end

  describe '#poster_url' do
    it 'provides a poster url' do
      expect(presenter.has_poster?).to eq true
      expect(presenter.poster_url).to eq Rails.application.routes.url_helpers.poster_collection_url(id)
    end

    context 'without a poster' do
      let(:has_poster) { false }

      it 'returns a default poster url' do
        expect(presenter.has_poster?).to eq false
        expect(presenter.poster_url).to eq ActionController::Base.helpers.asset_url('collection_icon.png')
      end
    end
  end

  describe '#collection_url' do
    it "provides the url to this collection's landing page" do
      expect(presenter.collection_url).to eq Rails.application.routes.url_helpers.collection_url(id)
    end
  end

  describe '#as_json' do
    subject(:presenter_json) { presenter.as_json({}) }
    it 'returns json' do
      expect(presenter_json[:id]).to eq id
      expect(presenter_json[:name]).to eq name
      expect(presenter_json[:unit]).to eq unit
      expect(presenter_json[:description]).to eq description
      expect(presenter_json[:poster_url]).to eq presenter.poster_url
      expect(presenter_json[:url]).to eq presenter.collection_url
    end
  end
end
