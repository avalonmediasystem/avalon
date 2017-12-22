# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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

  # if Blacklight::Utils.needs_attr_accessible?
  #   attr_accessible :email, :password, :password_confirmation
  # end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :trackable, :validatable
  devise :omniauthable

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    user_key
  end

  def destroy
    Bookmark.where(user_id: self.id).destroy_all
    super
  end

  def playlist_tags
    Playlist.where(user_id:id).collect(&:tags).flatten.reject(&:blank?).uniq.sort
  end

  def self.find_or_create_by_username_or_email(username, email)
    self.where(username: username).first ||
    self.where(email: email).first ||
    self.create(username: username, email: email)
  end

  def self.from_api_token(token)
    self.find_or_create_by_username_or_email(token.username, token.email)
  end

  def self.find_for_generic(access_token, signed_in_resource=nil)
    username = access_token.uid
    email = access_token.info.email
    User.find_by(username: username) || User.find_by(email: email) || User.create(username: username, email: email)
  end

  def self.find_for_identity(access_token, signed_in_resource=nil)
    username = access_token.info['email']
    # Use email for both username and email for the created user
    User.find_by(username: username) || User.find_by(email: username) || User.create(username: username, email: username)
  end

  def self.find_for_lti(auth_hash, signed_in_resource=nil)
    if auth_hash.uid.blank?
      raise Avalon::MissingUserId
    end

    class_id = auth_hash.extra.context_id
    if Course.where(context_id: class_id).empty?
      class_name = auth_hash.extra.context_name
      Course.create :context_id => class_id, :label => auth_hash.extra.consumer.context_label, :title => class_name unless class_name.nil?
    end

    self.find_or_create_by_username_or_email(auth_hash.uid, auth_hash.info.email)
  end

  def self.autocomplete(query)
    self.where("username LIKE :q OR email LIKE :q", q: "%#{query}%").collect { |user|
      { id: user.user_key, display: user.user_key }
    }
  end

  def in?(*list)
    list.flatten.include? user_key
  end

  #TODO extract the ldap stuff into a mixin?
  def ldap_groups
    User.walk_ldap_groups(User.ldap_member_of(user_key), []).sort
  end

  def self.ldap_member_of(cn)
    return [] unless defined? Avalon::GROUP_LDAP
    entry = Avalon::GROUP_LDAP.search(:base => Avalon::GROUP_LDAP_TREE, :filter => Net::LDAP::Filter.eq("cn", cn), :attributes => ["memberof"]).first
    entry.nil? ? [] : entry["memberof"].collect {|mo| mo.split(',').first.split('=').second}
  end

  def self.walk_ldap_groups(groups, seen)
    groups.each do |g|
      next if seen.include? g
      seen << g
      User.walk_ldap_groups(User.ldap_member_of(g), seen)
    end
    seen
  end
end

class Avalon::MissingUserId < StandardError; end
