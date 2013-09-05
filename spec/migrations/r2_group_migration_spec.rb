require 'spec_helper'
require File.join(Rails.root, 'db', 'migrate', '20130827145729_r2_group_migration')
 
describe R2GroupMigration do
  before(:all) do
    @groups = Admin::Group.all
    Admin::Group.all.map(&:delete)
  end

  after(:all) do
    @groups.each {|g| Admin::Group.create(name: g.name)}
    @groups.each do |g|
      Admin::Group.find(g.name).users = g.users
      g.save
    end
  end

  describe '#up' do

    before(:each) do
      Admin::Group.all.map(&:delete)
      FactoryGirl.create(:group, name: 'collection_manager')
      FactoryGirl.create(:group, name: 'group_manager')
    end

    it "should create the administrator group" do
      Admin::Group.find('administrator').should be_nil
      R2GroupMigration.new.up
      admin_group = Admin::Group.find('administrator')
      admin_group.should_not be_nil
      admin_group.users.should include(Admin::Group.find('group_manager').users.first)
    end
  end

end
