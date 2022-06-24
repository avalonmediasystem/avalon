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

describe SolrCollectionAdmin do
  subject { described_class.new }

  let(:solr_conn) { spy('solr_conn') }
  let(:collection) { subject.instance_variable_get(:@collection) }
  let(:location) { '/path/to/my/shared/drive' }
  let(:solr_core) do
    ActiveFedora.solr_config.fetch(:url, nil)&.split('/').last || 'hydra-test'
  end

  before do
    subject.instance_variable_set(:@conn, solr_conn)
  end

  describe 'backup' do
    it 'optimizes first if optimize option passed' do
      expect(solr_conn).to receive(:get).with("#{solr_core}/update", optimize: 'true')
      subject.backup(location, {optimize: true})
    end

    it 'calls backup and returns response' do
      backup_params = {action: 'BACKUP', collection: collection, location: location, wt: 'json'}
      expect(solr_conn).to receive(:get).with('admin/collections', hash_including(:name, backup_params))
      expect(subject.backup(location)).to include("responseHeader")
    end
  end

  describe 'restore' do
    it 'raises ArgumentError when missing name options' do
      expect { subject.restore(location) }.to raise_error(ArgumentError)
    end

    it 'calls restore and returns response' do
      restore_params = {action: 'RESTORE', collection: collection, location: location, wt: 'json'}
      expect(solr_conn).to receive(:get).with('admin/collections', hash_including(restore_params))
      expect(subject.restore(location, name: 'backup_name')).to include("responseHeader")
    end
  end
end
