# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

RSpec.describe "checkouts/index", type: :view do
  let(:user) { FactoryBot.create(:user) }
  let(:ability) { Ability.new(user) }
  let(:checkouts) { [FactoryBot.create(:checkout, checkout_time: Time.new(2000, 01, 13, 12, 0, 0)), FactoryBot.create(:checkout)] }
  before(:each) do
    assign(:checkouts, checkouts)
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:current_ability).and_return(ability)
  end
  context 'as a regular user' do
    it 'renders a list of checkouts without username' do
      render
      assert_select "tr>td", text: checkouts.first.user.user_key, count: 0
      assert_select "tr>td", text: checkouts.first.media_object.title
      assert_select "tr>td", text: checkouts.second.user.user_key, count: 0
      assert_select "tr>td", text: checkouts.second.media_object.title
    end
    context 'has no previously returned checkouts' do
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
    let(:user) { FactoryBot.create(:admin) }
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
  describe 'checkout and return time' do
    it 'renders UTC time in a span for JS conversion to local time zone' do
      render
      assert_select "tr>td>span[data-utc-time=?]", checkouts.first.checkout_time.iso8601
      assert_select "tr>td>span[data-utc-time=?]", checkouts.first.return_time.iso8601
    end
  end
end
