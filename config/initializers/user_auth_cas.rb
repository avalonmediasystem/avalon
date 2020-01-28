require 'net/ldap'

User.instance_eval do
  def self.find_for_cas(access_token, signed_in_resource=nil)
    logger.debug "#{access_token.inspect}"
    #data = access_token.info
    username = access_token.uid
    email = nil

    #If IU CAS guest account
    if username =~ /\d{11}/
      tree = "dc=eads,dc=iu,dc=edu"
      filter = Net::LDAP::Filter.construct("(&(objectCategory=CN=Person,CN=Schema,CN=Configuration,DC=eads,DC=iu,DC=edu)(cn=#{username}))")
      username = Avalon::IU_GUEST_LDAP.search(:base => tree, :filter => filter, :attributes=> ["mail"]).first.mail.first
      email = username
    end

    user = User.where(:username => username).first

    unless user
      if email.nil?
        tree = "dc=ads,dc=iu,dc=edu"
        filter = Net::LDAP::Filter.eq("cn", "#{username}")
        email = Avalon::GROUP_LDAP.search(:base => tree, :filter => filter, :attributes=> ["mail"]).first.mail.first
      end
      user = User.find_or_create_by_username_or_email(username, email)
      raise "Creating user (#{ user }) failed: #{ user.errors.full_messages }" unless user.persisted?
    end
    user
  end
end

