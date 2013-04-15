require 'spec_helper'

describe Admin::Group do
  describe "non system groups" do
    it "should not have system groups" do
      groups = Admin::Group.non_system_groups
      system_groups = Avalon::Configuration['groups']['system_groups']
      groups.each { |g| system_groups.should_not include g.name }
    end
  end

end
