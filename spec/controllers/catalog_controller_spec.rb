require 'spec_helper'

describe CatalogController do
  describe "#index" do
    describe "as an un-authenticated user" do
      it "should show results for items that are public and published" do
        mo = FactoryGirl.create(:published_media_object, access: 'public')
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(1)
        assigns(:document_list).map(&:id).should == [mo.id]
      end
      it "should not show results for items that are not public" do
        mo = FactoryGirl.create(:published_media_object, access: 'restricted')
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(0)
      end
      it "should not show results for items that are not published" do
        mo = FactoryGirl.create(:media_object, access: 'public')
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
      after do
        #TODO logout
      end
      it "should show results for items that are published and available to registered users" do
        mo = FactoryGirl.create(:published_media_object, access: 'restricted')
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(1)
        assigns(:document_list).map(&:id).should == [mo.id]
      end
      it "should not show results for items that are not public or available to registered users" do
        mo = FactoryGirl.create(:published_media_object, access: 'private')
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(0)
      end
      it "should not show results for items that are not published" do
        mo = FactoryGirl.create(:media_object, access: 'public')
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
        mo = FactoryGirl.create(:media_object, access: 'private', collection: collection)
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(1)
        assigns(:document_list).map(&:id).should == [mo.id]
      end
      it "should not show results for items that do not belong to one of my collections" do
        mo = FactoryGirl.create(:media_object, access: 'public')
        get 'index', :q => ""
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(0)
      end
    end
  end
end
