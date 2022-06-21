# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

class RoleMap < ActiveRecord::Base
  # belongs_to :role, class_name: "RoleMap", foreign_key: "parent_id"
  has_many :entries, class_name: "RoleMap", foreign_key: "parent_id"
  #attr_accessible :entry, :role, :parent_id

  def self.reset!
    self.replace_with! YAML.load(ERB.new(File.read(File.join(Rails.root, "config/role_map.yml"))).result).fetch(Rails.env)
  end

  def self.roles
    self.where(parent_id: nil)
  end

  def self.load(opts = {})
    Rails.cache.fetch('RoleMapHash', opts) do
      roles.inject({}) do |map, role|
        map[role.entry] = role.entries.collect &:entry
        map
      end
    end
  end

  def self.replace_with! map
    roles.each { |r| r.destroy unless map.keys.include?(r.entry) }
    map.each_pair do |role, entries|
      r = self.find_or_create_by(entry: role, parent_id: nil)
      r.set_entries entries
    end
    Rails.cache.delete('RoleMapHash')
  end

  def set_entries new_entries
    new_entries.reject! &:nil?
    existing = entries.collect &:entry
    add = new_entries - existing
    delete = existing - new_entries
    delete.each { |e| entries.find_by_entry(e).destroy }
    add.each    { |e| entries.create :entry => e       }
  end
end
