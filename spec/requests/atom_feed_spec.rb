require 'rails_helper'

describe 'atom feed', type: :request do
  it 'returns an atom feed' do
    get '/catalog.atom'
    expect(response).to be_successful
  end

  describe 'entry' do
    let!(:media_object) { FactoryBot.create(:fully_searchable_media_object) }
    let(:updated_date) { media_object.modified_date.to_time.utc.strftime('%Y-%m-%dT%H:%M:%SZ') }

    it 'returns information about a media object' do
      get '/catalog.atom'
      atom = Nokogiri::XML(response.body)
      atom.remove_namespaces!
      entry = atom.xpath('//entry[1]')
      expect(entry.at('id/text()').to_s).to eq media_object_url(media_object)
      expect(entry.at('updated/text()').to_s).to eq updated_date
      expect(entry.at("link[@type='application/json']/@href").to_s).to eq media_object_url(media_object, format: :json)
    end
  end
end
