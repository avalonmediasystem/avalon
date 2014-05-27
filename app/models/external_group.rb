require 'net/ldap'

class ExternalGroup

  def self.ldap_lookup(groupname, opts={})
    return [] unless defined? GROUP_LDAP
    filter = Net::LDAP::Filter.eq("cn", "#{groupname}") & Net::LDAP::Filter.eq("objectclass", "group")
    #Do not pass size to search since it always returns nil unless size is 0 for IU's AD
    result = GROUP_LDAP.search(:base => GROUP_LDAP_TREE, :filter => filter, :attributes => ["cn"]) #, :
    result.collect do |r|
      name = r['cn'].first
      { id: name, display: name }
    end
  end

  def self.ldap_autocomplete(query)
    #Only wildcard the tail of the query to avoid long running queries
    self.ldap_lookup("#{query}*", size: 10)
  end

  def self.autocomplete(query)
    Course.autocomplete(query) + self.ldap_autocomplete(query)
  end
end
