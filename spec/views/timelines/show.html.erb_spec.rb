require 'rails_helper'

RSpec.describe "timelines/show", type: :view do
  before(:each) do
    @timeline = assign(:timeline, Timeline.create!(
      :title => "Title",
      :user => nil,
      :visibility => "Visibility",
      :description => "MyText",
      :access_token => "Access Token",
      :tags => "Tags",
      :source => "Source",
      :manifest => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(//)
    expect(rendered).to match(/Visibility/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/Access Token/)
    expect(rendered).to match(/Tags/)
    expect(rendered).to match(/Source/)
    expect(rendered).to match(/MyText/)
  end
end
