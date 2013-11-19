# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

class User < ActiveRecord::Base
# Connects this user object to Hydra behaviors. 
 include Hydra::User
# Connects this user object to Blacklights Bookmarks and Folders. 
 include Blacklight::User
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable

  attr_accessible :username, :uid, :provider
  attr_accessible :email, :guest

  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  
  delegate :can?, :cannot?, :to => :ability

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account. 
  def to_s
    user_key
  end

  def self.find_for_identity(access_token, signed_in_resource=nil)
    username = access_token.info['email']
    User.find_or_create_by_username(username) do |u|
      u.email = username
    end
  end

  def self.find_for_lti(auth_hash, signed_in_resource=nil)
    logger.debug "In find_for_lti: #{auth_hash}"
    User.find_or_create_by_username auth_hash['uid'], email: auth_hash.info.email
  end

  def ability
    @ability ||= Ability.new(self)
  end

  def in?(*list)
    list.flatten.include? user_key
  end

  def groups
    RoleMapper.roles(user_key)
  end
end
