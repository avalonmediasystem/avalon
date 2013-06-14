module Avalon
  class NetID
    attr_reader :connection, :base
   
    def initialize(attrs={})
      provider = YAML.load(File.read(File.expand_path('../../config/nuldap_directory.yml',__FILE__))).first[:params]
      bind_attrs = {
        :host => provider[:host],
        :port => provider[:port], :encryption => :simple_tls, 
        :auth => { :method => :simple, :username => provider[:bind_dn], :password => provider[:password] }
      }.merge(attrs)
      @connection = Net::LDAP.new bind_attrs
      @base = provider[:base]
    end
   
    def search(filter, args={})
      query = { :base => base, :filter => (filter & Net::LDAP::Filter.eq('objectclass','person')) }.merge(args)
      connection.search(query)
    end
   
    def summary(filter, args={})
      result = search(filter, args.merge(:attributes => ['uid','mail','sn','givenname','displayname']))
      return [] unless result
      results = result.sort do |a,b|
        val = a[:sn].first.downcase <=> b[:sn].first.downcase
        if val == 0
          val = a[:givenname].first.downcase <=> b[:givenname].first.downcase
        end
        val
      end
   
      results.collect do |entry|
        as_json(entry)
      end
    end

    def as_json( entry )
      {
        uid: entry[:uid].first,
        email: entry[:mail].compact.first,
        first_name: entry[:givenname].first,
        last_name: entry[:sn].first,
        full_name: entry[:givenname].first + ' ' + entry[:sn].first,
        indirect_name: indirect_name(entry)
      }
    end
   
    def autocomplete(val)
      filter = Net::LDAP::Filter.begins('mail',val) | Net::LDAP::Filter.begins('cn',val) | Net::LDAP::Filter.eq('uid',val)
      summary(filter, :size => 20).map{ |e| self.class.format_autocomplete_entry( uid: e[:uid], full_name: e[:full_name], email: e[:email] ) }
    end

    def self.format_autocomplete_entry(args = {})
      Select2::Autocomplete.as_json( args[:uid], "#{args[:full_name]} (#{args[:email]})" )
    end
   
    def valid_uid?(net_id)
      find_by_net_id(net_id).length == 1
    end

    def find_by_uid(net_id)
      filter = Net::LDAP::Filter.eq('uid',net_id)
      result = search(filter, attributes: ['uid','mail','sn','givenname','displayname'] )
      return as_json(result.first) if result.length == 1
    end
   
    private
    def indirect_name(entry)
      [entry[:sn], entry[:givenname]].join(", ")
    end
  end
end