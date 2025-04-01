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

describe SolrCollectionCreator do
  subject { described_class.new(collection_name) }

  let(:solr_conn) { spy('solr_conn') }
  let(:collection_name) { 'my_collection' }

  before do
    allow(subject).to receive(:client).and_return(solr_conn)
  end

  describe 'perform' do
    it 'does nothing if collection already exists' do
      allow(subject).to receive(:collection_exists?).with(collection_name).and_return(true)
      expect(solr_conn).not_to receive(:get).with("/solr/admin/collections", hash_including(action: "CREATE"))
      subject.perform
    end

    it 'creates the collection' do
      allow(subject).to receive(:collection_exists?).with(collection_name).and_return(false)
      create_params = {action: 'CREATE', name: collection_name}
      expect(solr_conn).to receive(:get).with('/solr/admin/collections', {params: hash_including(create_params)})
      subject.perform
    end

    it 'passes along parameters in Settings' do
      collection_opts = {foo: 'bar'}
      allow(Settings.solr).to receive(:collection_options).and_return(collection_opts)
      allow(subject).to receive(:collection_exists?).with(collection_name).and_return(false)
      create_params = {action: 'CREATE', name: collection_name}
      expect(solr_conn).to receive(:get).with('/solr/admin/collections', {params: hash_including(create_params.merge(collection_opts))})
      subject.perform
    end
  end
end
