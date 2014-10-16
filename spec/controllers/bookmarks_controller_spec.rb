# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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
    login_user collection.managers.first
    3.times do
      media_objects << mo = FactoryGirl.create(:media_object, collection: collection)
      post :create, id: mo.id
    end
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
	expect(flash[:success]).to eq( I18n.t("blacklight.publish.success", count: 3, status: 'publish'))
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
	expect(flash[:success]).to eq( I18n.t("blacklight.publish.success", count: 3, status: 'unpublish'))
        media_objects.each do |mo|
          mo.reload
	  expect(mo).not_to be_published
        end
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
end
