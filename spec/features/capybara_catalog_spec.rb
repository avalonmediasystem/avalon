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

describe 'item catalog' do
  after { Warden.test_reset! }

  context 'unauthenticated user' do
    let!(:media_object) { FactoryBot.create(:fully_searchable_media_object, :with_master_file, avalon_uploader: 'admin@example.edu') }
    before :each do
      media_object.read_groups += ['ldap_group']
      media_object.save!
      # Perform indexing job so master file specific fields are added to the Media Object solr_doc
      MediaObjectIndexingJob.perform_now(media_object.id)
    end

    it 'verifies presence of all facet fields' do
      visit '/catalog'
      ['avalon_resource_type', 'creator', 'genre', 'series', 'collection', 'unit', 'language'].each do |field|
        expect(page).to have_selector(:id, "facet-#{field}_ssim-header")
      end
      expect(page).to have_selector(:id, "facet-date_sim-header")
      ['workflow_published_sim', 'avalon_uploader_ssi', 'read_access_group_ssim', 'read_access_virtual_group_ssim', 'date_digitized_ssim', 'date_ingested_ssim'].each do |field|
        expect(page).to_not have_selector(:id, "facet-#{field}-header")
      end
    end
  end

  context 'user who is not a collection manager' do
    let!(:media_object) { FactoryBot.create(:fully_searchable_media_object, :with_master_file, avalon_uploader: 'admin@example.edu') }

    before :each do
      media_object.read_groups += ['ldap_group']
      media_object.save!
      MediaObjectIndexingJob.perform_now(media_object.id)
      @user = FactoryBot.create(:user)
      login_as @user, scope: :user
    end

    it 'verifies presence of all facet fields' do
      visit '/catalog'
      ['avalon_resource_type', 'creator', 'genre', 'series', 'collection', 'unit', 'language'].each do |field|
        expect(page).to have_selector(:id, "facet-#{field}_ssim-header")
      end
      expect(page).to have_selector(:id, "facet-date_sim-header")
      ['workflow_published_sim', 'avalon_uploader_ssi', 'read_access_group_ssim', 'read_access_virtual_group_ssim', 'date_digitized_ssim', 'date_ingested_ssim'].each do |field|
        expect(page).to_not have_selector(:id, "facet-#{field}-header")
      end
    end
  end

  context 'user with collection manager permissions' do
    let(:manager) { FactoryBot.create(:manager) }
    let!(:collection) { FactoryBot.create(:collection, managers: [manager.user_key]) }
    let!(:media_object) { FactoryBot.create(:fully_searchable_media_object, :with_master_file, avalon_uploader: 'admin@example.edu', collection: collection) }

    before :each do
      media_object.read_groups += ['ldap_group']
      media_object.save!
      MediaObjectIndexingJob.perform_now(media_object.id)
      login_as manager, scope: :user
    end

    it 'verifies presence of all facet fields' do
      visit '/catalog'
      ['avalon_resource_type', 'creator', 'genre', 'series', 'collection', 'unit', 'language'].each do |field|
        expect(page).to have_selector(:id, "facet-#{field}_ssim-header")
      end
      expect(page).to have_selector(:id, "facet-date_sim-header")
      ['workflow_published_sim', 'avalon_uploader_ssi', 'read_access_group_ssim', 'read_access_virtual_group_ssim', 'date_digitized_ssim', 'date_ingested_ssim'].each do |field|
        expect(page).to have_selector(:id, "facet-#{field}-header")
      end
    end
  end

  context 'admin user' do
    let!(:media_object) { FactoryBot.create(:fully_searchable_media_object, :with_master_file, avalon_uploader: 'admin@example.edu') }

    before :each do
      media_object.read_groups += ['ldap_group']
      media_object.save!
      MediaObjectIndexingJob.perform_now(media_object.id)
      @user = FactoryBot.create(:administrator)
      login_as @user, scope: :user
    end

    it 'verifies presence of all facet fields' do
      visit '/catalog'
      ['avalon_resource_type', 'creator', 'genre', 'series', 'collection', 'unit', 'language'].each do |field|
        expect(page).to have_selector(:id, "facet-#{field}_ssim-header")
      end
      expect(page).to have_selector(:id, "facet-date_sim-header")
      ['workflow_published_sim', 'avalon_uploader_ssi', 'read_access_group_ssim', 'read_access_virtual_group_ssim', 'date_digitized_ssim', 'date_ingested_ssim'].each do |field|
        expect(page).to have_selector(:id, "facet-#{field}-header")
      end
    end
  end
end
