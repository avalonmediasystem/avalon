
require 'spec_helper'


describe 'NotificationsMailer' do

  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe '#new_collection' do
    let(:collection){ FactoryGirl.create(:collection) }
    before(:each) do
      @creator    = FactoryGirl.create(:user)
      @admin_user = FactoryGirl.create(:user) 
      @collection = FactoryGirl.create(:collection)

      @email = NotificationsMailer.new_collection( 
        creator_id: @creator.id, 
        collection_id: @collection.id, 
        user_id: @admin_user.id, 
        subject: "New collection: #{@collection.name}",
      )
    end
    
    it 'has correct e-mail address' do
      @email.should deliver_to(@admin_user.email)
    end

    context 'subject' do
      it 'has collection name' do
        @email.should have_subject(/#{@collection.name}/)
      end
    end
    
    context 'body' do
      it 'has collection name' do
        @email.should have_body_text(@collection.name)
      end
      
      it 'has creator e-mail' do
        @email.should have_body_text(@creator.email)
      end

      it 'has collection description' do
        @email.should have_body_text(@collection.description)
      end

      it 'has unit name' do
        @email.should have_body_text(@collection.unit)
      end
    end
  end
end
