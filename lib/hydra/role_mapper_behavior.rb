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

require 'yaml'
module Hydra::RoleMapperBehavior
  extend ActiveSupport::Concern

  module ClassMethods
    def role_names
      map.keys
    end

    def roles(user_or_uid)
      if user_or_uid.kind_of?(String)
        user = ::User.find_by_user_key(user_or_uid)
        user_id = user_or_uid
      elsif user_or_uid.kind_of?(::User) && user_or_uid.user_key
        user = user_or_uid
        user_id = user.user_key
      end
      array = byname[user_id].dup || []
      array = array << 'registered' unless (user.nil? || user.new_record?)
      array
    end

    def whois(r)
      map[r]
    end

    def map
      @map ||= YAML.load(File.open(File.join(Rails.root, "config/role_map_#{Rails.env}.yml")))
    end


    def byname
      m = Hash.new{|h,k| h[k]=[]}
      @byname = map.inject(m) do|memo, (role,usernames)|
        ((usernames if usernames.respond_to?(:each)) || [usernames]).each { |x| memo[x]<<role}
        memo
      end
    end

  end
end
