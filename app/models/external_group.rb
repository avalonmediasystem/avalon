# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

require 'net/ldap'

class ExternalGroup

  def self.ldap_lookup(groupname, opts={})
    return [] unless defined? Avalon::GROUP_LDAP
    filter = Net::LDAP::Filter.eq("cn", "#{groupname}") & Net::LDAP::Filter.eq("objectclass", "group")
    #Do not pass size to search since it always returns nil unless size is 0 for IU's AD
    result = Avalon::GROUP_LDAP.search(:base => Avalon::GROUP_LDAP_TREE, :filter => filter, :attributes => ["cn"]) #, :
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
