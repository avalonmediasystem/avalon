class RoleMap < ActiveRecord::Base
  belongs_to :role, class_name: "RoleMap", foreign_key: "parent_id"
  has_many :entries, class_name: "RoleMap", foreign_key: "parent_id"
  attr_accessible :entry, :role

  def self.reset!
    self.replace_with! YAML.load(File.read(File.join(Rails.root, "config/role_map_#{Rails.env}.yml")))
  end

  def self.roles
    self.find_all_by_parent_id(nil)
  end

  def self.load
    Rails.cache.fetch('RoleMapHash') do
      roles.inject({}) do |map, role|
        map[role.entry] = role.entries.collect &:entry
        map
      end
    end
  end

  def self.replace_with! map
    roles.each { |r| r.destroy unless map.keys.include?(r.entry) }
    map.each_pair do |role, entries|
      r = self.find_or_create_by_entry_and_parent_id(role, nil)
      existing = r.entries.collect &:entry
      add = entries - existing
      delete = existing - entries
      delete.each { |e| r.entries.find_by_entry(e).destroy }
      add.each { |e| r.entries.create :entry => e }
    end
    Rails.cache.delete('RoleMapHash')
  end
end

module Hydra::RoleMapperBehavior::ClassMethods
  def map
    RoleMap.reset! if RoleMap.count == 0
    RoleMap.load
  end

  def update
    m = map
    yield m
    RoleMap.replace_with! m
  end
end
