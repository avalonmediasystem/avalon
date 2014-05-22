require File.join(Rails.root,'app/models/admin/group')
require File.join(Rails.root,'app/models/user')
require 'net/ldap'

IU_LDAP_TREE = "dc=ads,dc=iu,dc=edu"

Admin::Group.instance_eval do
  def self.ldap_lookup(groupname, opts={})
    filter = Net::LDAP::Filter.eq("cn", "#{groupname}") & Net::LDAP::Filter.eq("objectType", "group")
    result = IU_LDAP.search(:base => IU_LDAP_TREE, :filter => filter, :attributes => ["cn"]) #, :size => opts[:limit])
    result.collect do |r|
      name = r['cn'].first
      { id: name, display: name }
    end
  end

  def self.autocomplete(query)
    self.ldap_lookup("#{query}*", size: 10)
  end
end

User.instance_eval do

  def self.ldap_member_of(cn)
    group_cns = IU_LDAP.search(:base => "dc=ads,dc=iu,dc=edu", :filter => Net::LDAP::Filter.eq("cn", cn), :attributes => ["memberof"]).first["memberof"] rescue []
    group_cns.collect {|mo| mo.split(',').first.split('=').second}
  end

  def self.visit_parent_ldap_groups(groups, seen)
    groups.each do |g|
      next if seen.include? g
      seen << g
      visit_parent_ldap_groups(ldap_member_of(g), seen)
    end
  end

  def self.find_ldap_groups(username)
    groups = []
    visit_parent_ldap_groups(ldap_member_of(username), groups)
    groups.sort
  end
end
