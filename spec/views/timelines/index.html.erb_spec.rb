require 'rails_helper'

RSpec.describe "timelines/index", type: :view do
  before(:each) do
    assign(:timelines, [
      Timeline.create!(
        :title => "Title",
        :user => nil,
        :visibility => "Visibility",
        :description => "MyText",
        :access_token => "Access Token",
        :tags => "Tags",
        :source => "Source",
        :manifest => "MyText"
      ),
      Timeline.create!(
        :title => "Title",
        :user => nil,
        :visibility => "Visibility",
        :description => "MyText",
        :access_token => "Access Token",
        :tags => "Tags",
        :source => "Source",
        :manifest => "MyText"
      )
    ])
  end

  it "renders a list of timelines" do
    render
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => "Visibility".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "Access Token".to_s, :count => 2
    assert_select "tr>td", :text => "Tags".to_s, :count => 2
    assert_select "tr>td", :text => "Source".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
