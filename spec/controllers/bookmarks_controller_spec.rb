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

describe BookmarksController, type: :controller do
  render_views

  let!(:collection) { FactoryGirl.create(:collection) }
  let!(:media_objects) { [] }
    
  before(:each) do
    request.env["HTTP_REFERER"] = '/'
    Delayed::Worker.delay_jobs = false
    login_user collection.managers.first
    3.times do
      media_objects << mo = FactoryGirl.create(:media_object, collection: collection)
      post :create, id: mo.id
    end
  end

  after(:each) do
    Delayed::Worker.delay_jobs = true
  end

  describe "#destroy" do
    it "should remove multiple items" do
      post :delete
      expect(flash[:success]).to eq(I18n.t("blacklight.delete.success", count: 3))
      media_objects.each {|mo| expect(MediaObject.exists?(mo.pid)).to be_falsey }
    end
  end

  describe "#update_status" do
    context 'publishing' do
      before(:each) do
        Permalink.on_generate { |obj| "http://example.edu/permalink" }
      end

      it "should publish multiple items" do
        post 'publish'
	expect(flash[:success]).to eq( I18n.t("blacklight.status.success", count: 3, status: 'publish'))
        media_objects.each do |mo|
          mo.reload
	  expect(mo).to be_published
	  expect(mo.permalink).to be_present
        end
      end
    end

    context 'unpublishing' do
      it "should unpublish multiple items" do
        post 'unpublish'
	expect(flash[:success]).to eq( I18n.t("blacklight.status.success", count: 3, status: 'unpublish'))
        media_objects.each do |mo|
          mo.reload
	  expect(mo).not_to be_published
        end
      end
    end
  end

  describe "index" do
    context 'action buttons' do
      it 'are displayed for authorized user' do
        get 'index'
        expect(response.body).to have_css('#moveLink')
        expect(response.body).to have_css('#publishLink')
        expect(response.body).to have_css('#unpublishLink')
        expect(response.body).to have_css('#deleteLink')
      end
      it 'are not displayed for unauthorized user' do
        collection.managers = [FactoryGirl.create(:manager).username]
        collection.save
        get 'index'
        expect(response.body).not_to have_css('#moveLink')
        expect(response.body).not_to have_css('#publishLink')
        expect(response.body).not_to have_css('#unpublishLink')
        expect(response.body).not_to have_css('#deleteLink')        
      end
    end
  end

  describe "#move" do
    let!(:collection2) { FactoryGirl.create(:collection) }

    context 'user has no permission on target collection' do
      it 'responds with error message' do
        post 'move', target_collection_id: collection2.id
	expect(flash[:error]).to eq( I18n.t("blacklight.move.error", collection_name: collection2.name))
      end
    end
    context 'user has permission on target collection' do
      it 'moves items to selected collection' do
        collection2.managers = collection.managers
        collection2.save
        post 'move', target_collection_id: collection2.id
        expect(flash[:success]).to eq( I18n.t("blacklight.move.success", count: 3, collection_name: collection2.name))
        media_objects.each do |mo|
          mo.reload
          expect(mo.collection).to eq(collection2)
        end
      end
    end
  end

  describe '#update_access_control' do
    it 'changes to hidden' do
      post 'update_access_control', hidden: "true"
      expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
      media_objects.each do |mo|
        mo.reload
        expect(mo.hidden?).to be_truthy
      end
    end
    it 'changes to shown' do
      post 'update_access_control', hidden: "false"
      expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
      media_objects.each do |mo|
        mo.reload
        expect(mo.hidden?).to be_falsey
      end
    end
    it 'changes the visibility' do
      post 'update_access_control', visibility: 'public'
      expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
      media_objects.each do |mo|
        mo.reload
        expect(mo.visibility).to eq 'public'
      end
    end
    context 'Limited access' do
      context 'users' do
	it 'adds a user to the selected items' do
          post 'update_access_control', submit_add_user: 'Add', user: 'cjcolvar'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.read_users).to include 'cjcolvar'
          end
        end
	it 'adds a time-based user to the selected items' do
          post 'update_access_control', submit_add_user: 'Add', add_user_begin: Date.yesterday, add_user_end: Date.today, user: 'cjcolvar'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.governing_policies[1].read_users).to include 'cjcolvar'
            expect(mo.governing_policies[1].begin_time).to eq DateTime.parse(Date.yesterday.to_s).utc.beginning_of_day.iso8601
            expect(mo.governing_policies[1].end_time).to eq DateTime.parse(Date.today.to_s).utc.end_of_day.iso8601
          end
        end

	it 'removes a user from the selected items' do
          media_objects.each do |mo|
            mo.read_users += ["john.doe"]
            mo.save
            mo.reload
          end
          post 'update_access_control', submit_remove_user: 'Remove', user: 'john.doe'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.read_users).not_to include 'john.doe'
          end
        end
	it 'removes a time-based user from the selected items' do
          media_objects.each do |mo|
            mo.governing_policies += [Lease.create(begin_time: Date.today-2.day, end_time: Date.yesterday, read_users: ['jane.doe'])]
            mo.save
            mo.reload
          end
          post 'update_access_control', submit_remove_user: 'Remove', user: 'john.doe'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.governing_policies.collect{|p|p.read_users}.flatten.uniq.compact).not_to include 'john.doe'
          end
        end
      end
      context 'groups' do
	it 'adds a group to the selected items' do
          post 'update_access_control', submit_add_group: 'Add', group: 'students'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.read_groups).to include 'students'
          end
        end
	it 'adds a time-based group to the selected items' do
          post 'update_access_control', submit_add_group: 'Add', add_group_begin: Date.yesterday, add_group_end: Date.today, group: 'students'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.governing_policies[1].read_groups).to include 'students'
            expect(mo.governing_policies[1].begin_time).to eq DateTime.parse(Date.yesterday.to_s).utc.beginning_of_day.iso8601
            expect(mo.governing_policies[1].end_time).to eq DateTime.parse(Date.today.to_s).utc.end_of_day.iso8601
          end
        end
	it 'removes a group from the selected items' do
          media_objects.each do |mo|
            mo.read_groups += ["test-group"]
            mo.save
            mo.reload
          end
          post 'update_access_control', submit_remove_group: 'Remove', group: 'test-group'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.read_groups).not_to include 'test-group'
          end
        end
	it 'removes a time-based group from the selected items' do
          media_objects.each do |mo|
            mo.governing_policies += [Lease.create(begin_time: Date.today-2.day, end_time: Date.yesterday, read_groups: ['test-group'])]
            mo.save
            mo.reload
          end
          post 'update_access_control', submit_remove_group: 'Remove', group: 'test-group'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.governing_policies.collect{|p|p.read_groups}.flatten.uniq.compact).not_to include 'test-group'
          end
        end
      end
      context 'external groups' do
	it 'adds an external group to the selected items' do
          post 'update_access_control', submit_add_class: 'Add', class: 'ECON-101'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.read_groups).to include 'ECON-101'
          end
        end
	it 'adds a time-based external group to the selected items' do
          post 'update_access_control', submit_add_class: 'Add', add_class_begin: Date.yesterday, add_class_end: Date.today, class: 'ECON-101'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.governing_policies[1].read_groups).to include 'ECON-101'
            expect(mo.governing_policies[1].begin_time).to eq DateTime.parse(Date.yesterday.to_s).utc.beginning_of_day.iso8601
            expect(mo.governing_policies[1].end_time).to eq DateTime.parse(Date.today.to_s).utc.end_of_day.iso8601
          end
        end
	it 'removes an external group from the selected items' do
          media_objects.each do |mo|
            mo.read_groups += ["MUSIC-101"]
            mo.save
            mo.reload
          end
          post 'update_access_control', submit_remove_class: 'Remove', class: 'MUSIC-101'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.read_groups).not_to include 'MUSIC-101'
          end
        end
	it 'removes a time-based external group from the selected items' do
          media_objects.each do |mo|
            mo.governing_policies += [Lease.create(begin_time: Date.today-2.day, end_time: Date.yesterday, read_groups: ['MUSIC-101'])]
            mo.save
            mo.reload
          end
          post 'update_access_control', submit_remove_class: 'Remove', class: 'MUSIC-101'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.governing_policies.collect{|p|p.read_groups}.flatten.uniq.compact).not_to include 'MUSIC-101'
          end
        end
      end
      context 'ip groups' do
	it 'adds an ip group to the selected items' do
          post 'update_access_control', submit_add_ipaddress: 'Add', ipaddress: '127.0.0.127'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.read_groups).to include '127.0.0.127'
          end
        end
	it 'adds a time-based ip group to the selected items' do
          post 'update_access_control', submit_add_ipaddress: 'Add', add_ipaddress_begin: Date.yesterday, add_ipaddress_end: Date.today, ipaddress: '127.0.0.127'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.governing_policies[1].read_groups).to include '127.0.0.127'
            expect(mo.governing_policies[1].begin_time).to eq DateTime.parse(Date.yesterday.to_s).utc.beginning_of_day.iso8601
            expect(mo.governing_policies[1].end_time).to eq DateTime.parse(Date.today.to_s).utc.end_of_day.iso8601
          end
        end
	it 'removes an ip group from the selected items' do
          media_objects.each do |mo|
            mo.read_groups += ["127.0.0.127"]
            mo.save
            mo.reload
          end
          post 'update_access_control', submit_remove_ipaddress: 'Remove', ipaddress: '127.0.0.127'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.read_groups).not_to include '127.0.0.127'
          end
        end
	it 'removes a time-based ip group from the selected items' do
          media_objects.each do |mo|
            mo.governing_policies += [Lease.create(begin_time: Date.today-2.day, end_time: Date.yesterday, read_groups: ['127.0.0.127'])]
            mo.save
            mo.reload
          end
          post 'update_access_control', submit_remove_ipaddress: 'Remove', ipaddress: '127.0.0.127'
          expect(flash[:success]).to eq( I18n.t("blacklight.update_access_control.success", count: 3))
          media_objects.each do |mo|
            mo.reload
            expect(mo.governing_policies.collect{|p|p.read_groups}.flatten.uniq.compact).not_to include '127.0.0.127'
          end
        end
      end
    end
  end
end
