require 'spec_helper'

describe User do
  describe "Ability" do
    before (:each) do
      @user = User.new
      @user.username = "test"
      @mo = MediaObject.new
      @mo.save(:validate=>false)
    end

    it "should have an ability" do
      @user.ability.should_not be_nil
    end

    it "should not be able to read any MediaObject" do
      assert @user.cannot?(:read, @mo)
    end

    it "should not be able to read authorized, unpublished MediaObject" do
      @mo.read_users = [@user.user_key]
      assert @user.cannot?(:read, @mo)
    end

    it "should be able to read authorized, published MediaObject" do
      @mo.read_users += [@user.user_key]
      @mo.avalon_publisher = ["random"]
      @mo.save(:validate=>false)
      assert @user.can?(:read, @mo)
    end
  end
end
