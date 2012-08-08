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