require 'rails_helper'

RSpec.describe "timelines/new", type: :view do
  before(:each) do
    assign(:timeline, Timeline.new(
      :title => "MyString",
      :user => nil,
      :visibility => "MyString",
      :description => "MyText",
      :access_token => "MyString",
      :tags => "MyString",
      :source => "MyString",
      :manifest => "MyText"
    ))
  end

  it "renders new timeline form" do
    render

    assert_select "form[action=?][method=?]", timelines_path, "post" do

      assert_select "input[name=?]", "timeline[title]"

      assert_select "input[name=?]", "timeline[user_id]"

      assert_select "input[name=?]", "timeline[visibility]"

      assert_select "textarea[name=?]", "timeline[description]"

      assert_select "input[name=?]", "timeline[access_token]"

      assert_select "input[name=?]", "timeline[tags]"

      assert_select "input[name=?]", "timeline[source]"

      assert_select "textarea[name=?]", "timeline[manifest]"
    end
  end
end
