require 'net/ldap'

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
  
  delegate :can?, :cannot?, :to => :ability

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account. 
  def to_s
    username
  end

  def self.find_for_cas(access_token, signed_in_resource=nil)
    logger.debug "#{access_token.inspect}"
    #data = access_token.info
    username = access_token.uid

    #If IU CAS guest account
    if username =~ /\d{11}/
      tree = "dc=eads,dc=iu,dc=edu"
      filter = Net::LDAP::Filter.construct("(&(objectCategory=CN=Person,CN=Schema,CN=Configuration,DC=eads,DC=iu,DC=edu)(cn=#{username}))")
      username = HYDRANT_LDAP.search(:base => tree, :filter => filter, :attributes=> ["mail"]).first.mail.first
    end

    user = User.where(:username => username).first

    unless user
        user = User.create(username: username)
    end
    user
  end

  def self.find_for_ldap(access_token, signed_in_resource=nil)
    username = access_token.info['email']
    User.where(:username => username).first || User.create(:username => username)
  end

  def self.find_for_identity(access_token, signed_in_resource=nil)
    username = access_token.info['email']
    user = User.where(:username => username).first

    unless user
      user = User.create(username: username)
    end
    user
  end

  def ability
    @ability ||= Ability.new(self)
  end
end
