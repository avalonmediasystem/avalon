require 'spec_helper'

describe RoleMap do
  describe "role map persistor" do
    before :each do
      RoleMap.reset!
    end

    after :each do
      RoleMap.all.each &:destroy
    end

    it "should properly initialize the map" do
      RoleMapper.map.should == YAML.load(File.read(File.join(Rails.root, "config/role_map_#{Rails.env}.yml")))
    end

    it "should properly persist a hash" do
      new_hash = { 'archivist' => ['alice.archivist@example.edu'], 'registered' => ['bob.user@example.edu','charlie.user@example.edu'] }
      RoleMap.replace_with!(new_hash)
      RoleMapper.map.should == new_hash
      RoleMap.load.should == new_hash
    end
  end
end
