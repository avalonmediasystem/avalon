require 'rails_helper'

RSpec.describe "checkouts/index", type: :view do
  let(:checkouts) { [FactoryBot.create(:checkout), FactoryBot.create(:checkout)] }
  before(:each) do
    assign(:checkouts, checkouts)
  end

  it "renders a list of checkouts" do
    render
    assert_select "tr>td", text: checkouts.first.user.user_key
    assert_select "tr>td", text: checkouts.first.media_object.title
    assert_select "tr>td", text: checkouts.second.user.user_key
    assert_select "tr>td", text: checkouts.second.media_object.title
  end
end
