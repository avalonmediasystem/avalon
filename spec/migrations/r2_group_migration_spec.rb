# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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
