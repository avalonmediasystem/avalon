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

describe Permalink do

  describe '#permalink' do

    let(:master_file){ FactoryBot.build(:master_file) }

    context 'permalink does not exist' do
      it 'returns nil' do
        expect(master_file.permalink).to be_nil
      end

      it 'returns nil with query variables' do
        expect(master_file.permalink({a:'b'})).to be_nil
      end
    end

    context 'permalink exists' do

      let(:permalink_url){ "http://permalink.com/object/#{master_file.id}" }

      before do
        master_file.permalink = permalink_url
      end

      it 'returns a string' do
        expect(master_file.permalink).to be_kind_of(String)
      end

      it 'appends query variables to the url' do
        query_var_hash = { urlappend: '/embed' }
        expect(master_file.permalink_with_query(query_var_hash)).to eq("#{permalink_url}?#{query_var_hash.to_query}")
      end
    end

    context 'creating permalink' do
      let(:media_object) do
        mo = FactoryBot.build(:media_object)
        mo.save
        mo.reload
      end
      let(:master_file) { FactoryBot.create(:master_file, media_object: media_object) }

      it 'should get the absolute path to the object' do
        expect(Permalink.url_for(media_object)).to eq("http://test.host/media_objects/#{CGI::escape(media_object.id)}")
        expect(Permalink.url_for(master_file)).to eq("http://test.host/media_objects/#{CGI::escape(media_object.id)}/section/#{CGI::escape(master_file.id)}")
      end

      it 'permalink_for raises ArgumentError if not passed media_object or master_file' do
        expect{Permalink.permalink_for(Object.new)}.to raise_error(ArgumentError)
      end
    end

  end
end
