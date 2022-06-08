require 'rails_helper'

RSpec.describe "checkouts/index", type: :view do
  let(:user) { FactoryBot.create(:user) }
  let(:checkouts) { [FactoryBot.create(:checkout), FactoryBot.create(:checkout)] }
  before(:each) do
    assign(:checkouts, checkouts)
    allow(view).to receive(:current_user).and_return(user)
  end
  context 'as a regular user' do
    it 'renders a list of checkouts without username' do
      render
      assert_select "tr>td", text: checkouts.first.user.user_key, count: 0
      assert_select "tr>td", text: checkouts.first.media_object.title
      assert_select "tr>td", text: checkouts.second.user.user_key, count: 0
      assert_select "tr>td", text: checkouts.second.media_object.title
    end
    context 'no previously returned checkouts' do
      it 'does not render the show inactive checkouts checkbox' do
        render
        expect(response).not_to render_template('checkouts/_inactive_checkout')
      end
    end
    context 'has previously returned checkouts' do
      before { FactoryBot.create(:checkout, user: user, return_time: DateTime.current - 1.week) }
      it 'renders the show inactive checkouts checkbox' do
        render
        expect(response).to render_template('checkouts/_inactive_checkout')
      end
    end
  end
  context 'as an admin user' do
    let(:admin) { FactoryBot.create(:admin) }
    before { allow(view).to receive(:current_user).and_return(admin) }
    it 'renders a list of checkouts with usernames' do
      render
      assert_select "tr>td", text: checkouts.first.user.user_key
      assert_select "tr>td", text: checkouts.first.media_object.title
      assert_select "tr>td", text: checkouts.second.user.user_key
      assert_select "tr>td", text: checkouts.second.media_object.title
    end
    it 'renders the show inactive checkouts checkbox' do
      render
      expect(response).to render_template('checkouts/_inactive_checkout')
    end
  end
  describe 'media object entry' do
    it 'is a link' do
      render
      assert_select "tr>td", html: "<a href=\"#{media_object_url(checkouts.first.media_object_id)}\">#{checkouts.first.media_object.title}</a>"
    end
  end
end
