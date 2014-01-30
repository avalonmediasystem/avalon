# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

describe CatalogController do
  describe "#index" do
    describe "as an un-authenticated user" do
      it "should show results for items that are public and published" do
        mo = FactoryGirl.create(:published_media_object, visibility: 'public')
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(1)
        assigns(:document_list).map(&:id).should == [mo.id]
      end
      it "should not show results for items that are not public" do
        mo = FactoryGirl.create(:published_media_object, visibility: 'restricted')
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(0)
      end
      it "should not show results for items that are not published" do
        mo = FactoryGirl.create(:media_object, visibility: 'public')
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(0)
      end
    end
    describe "as an authenticated user" do
      before do
        login_as :user
      end
      it "should show results for items that are published and available to registered users" do
        mo = FactoryGirl.create(:published_media_object, visibility: 'restricted')
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(1)
        assigns(:document_list).map(&:id).should == [mo.id]
      end
      it "should not show results for items that are not public or available to registered users" do
        mo = FactoryGirl.create(:published_media_object, visibility: 'private')
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(0)
      end
      it "should not show results for items that are not published" do
        mo = FactoryGirl.create(:media_object, visibility: 'public')
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(0)
      end
    end
    describe "as a manager" do
      let!(:collection) {FactoryGirl.create(:collection)}
      let!(:manager) {login_user(collection.managers.first)}

      it "should show results for items that are unpublished, private, and belong to one of my collections" do
        mo = FactoryGirl.create(:media_object, visibility: 'private', collection: collection)
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(1)
        assigns(:document_list).map(&:id).should == [mo.id]
      end
      it "should not show results for items that do not belong to one of my collections" do
        mo = FactoryGirl.create(:media_object, visibility: 'private')
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(0)
      end
    end
		describe "as an administrator" do
			let!(:administrator) {login_as(:administrator)}

			it "should show results for all items" do
        mo = FactoryGirl.create(:media_object, visibility: 'private')
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(1)
        assigns(:document_list).map(&:id).should == [mo.id]
      end
		end
    describe "as an lti user" do
      let!(:user) { login_lti 'student' }
      let!(:lti_group) { @controller.user_session[:virtual_groups].first }
      it "should show results for items visible to the lti virtual group" do
        mo = FactoryGirl.create(:published_media_object, visibility: 'private', read_groups: [lti_group])
        get 'index', :q => "read_access_virtual_group_ssim:#{lti_group}"
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(1)
        assigns(:document_list).map(&:id).should == [mo.id]
      end
    end
  end
end
