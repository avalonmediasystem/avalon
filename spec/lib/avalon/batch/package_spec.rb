# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

describe Avalon::Batch::Ingest do
  let(:manager) { FactoryBot.create(:manager, username: 'frances.dickens@reichel.com', email: 'frances.dickens@reichel.com') }
  let(:collection) { FactoryBot.build(:collection, managers: [manager.user_key]) }
  let(:manifest_file) { File.new('spec/fixtures/dropbox/example_batch_ingest/batch_manifest.xlsx') }
  let(:package) { Avalon::Batch::Package.new(manifest_file, collection) }
  let(:entry) { package.manifest.entries.first }

  describe 'avalon_uploader' do
    it 'correctly reads the manifest' do
      expect(package.manifest.email).to eq 'frances.dickens@reichel.com'
    end
    it 'correctly looks up the user' do
      expect(package.user).to eq manager
    end
  end

  describe 'hidden' do
    let(:entry_hidden) { package.manifest.entries.second }

    it 'correctly reads hidden from the manifest' do
      expect(entry.opts[:hidden]).to be_falsey
      expect(entry_hidden.opts[:hidden]).to be_truthy
    end
  end

  describe 'bibliographic import' do
    let(:entry) { package.manifest.entries.third }

    it 'correctly reads bib info from the manifest' do
      expect(entry.fields[:bibliographic_id]).to eq ['7763100']
      expect(entry.fields[:bibliographic_id_label]).to eq ['local']
    end
  end

  describe 'other identifiers' do
    it 'correctly reads other identifiers from the manifest' do
      expect(entry.fields[:other_identifier]).to eq ['ABC123']
      expect(entry.fields[:other_identifier_type]).to eq ['local']
    end
  end

  describe 'notes' do
    it 'correctly reads notes from the manifest' do
      expect(entry.fields[:note]).to eq ['This is a test general note']
      expect(entry.fields[:note_type]).to eq ['general']
    end
  end
end
