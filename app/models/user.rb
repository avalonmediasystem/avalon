class User < ActiveRecord::Base
# Connects this user object to Hydra behaviors. 
 include Hydra::User
# Connects this user object to Blacklights Bookmarks and Folders. 
 include Blacklight::User
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable

  attr_accessible :username, :uid, :provider
  
  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account. 
  def to_s
    username.blank? ? uid : username
  end

  def self.find_for_cas(access_token, signed_in_resource=nil)
    data = access_token.info
    user = User.where(:username => data["user"]).first

    unless user
        user = User.create(username: data["user"])
    end
    user
  end
end
