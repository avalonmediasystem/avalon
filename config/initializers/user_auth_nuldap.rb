require 'net/ldap'
 
User.instance_eval do
  def self.find_for_nuldap(access_token, signed_in_resource=nil)
    User.find_or_create_by_username( access_token.info['email']){ |u|
      u.email = access_token.info['email']
    }
  end
end