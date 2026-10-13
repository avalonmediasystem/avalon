require 'active-fedora'

module Blacklight::AccessControls::Enforcement
  def apply_group_permissions(permission_types, ability = current_ability)
    groups = ability.user_groups
    return [] if groups.empty?
    permission_types.map do |type|
      field = solr_field_for(type, 'group')
      "_query_:\"{!terms f=#{field}}#{groups.join(',')}\"" # nested query needed for solr to properly parse terms when any have spaces in them
    end
  end
end

# Override to also escape single quote '
module RSolr
  # backslash escape characters that have special meaning to Solr query parser
  # per http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html#Escaping_Special_Characters
  #  + - & | ! ( ) { } [ ] ^ " ~ * ? : \ /
  # see also http://svn.apache.org/repos/asf/lucene/dev/tags/lucene_solr_4_9_1/solr/solrj/src/java/org/apache/solr/client/solrj/util/ClientUtils.java
  #   escapeQueryChars method
  # @return [String] str with special chars preceded by a backslash
  def self.solr_escape(str)
    # note that the gsub will parse the escaped backslashes, as will the ruby code sending the query to Solr
    # so the result sent to Solr is ultimately a single backslash in front of the particular character
    str.gsub(/([+\-&|!\(\)\{\}\[\]\^"'~\*\?:\\\/\$])/, '\\\\\1')
  end
end

RSolr::Client.class_eval do
  # OVERRIDE: add post method to retry config
  def connection
    @connection ||= begin
      conn_opts = { request: {} }
      conn_opts[:url] = uri.to_s
      conn_opts[:proxy] = proxy if proxy
      conn_opts[:request][:open_timeout] = options[:open_timeout] if options[:open_timeout]

      if options[:read_timeout] || options[:timeout]
        # read_timeout was being passed to faraday as timeout since Rsolr 2.0,
        # it's now deprecated, just use `timeout` directly.
        conn_opts[:request][:timeout] = options[:timeout] || options[:read_timeout]
      end

      conn_opts[:request][:params_encoder] = Faraday::FlatParamsEncoder

      Faraday.new(conn_opts) do |conn|
        if uri.user && uri.password
          case Faraday::VERSION
          when /^0/
            conn.basic_auth uri.user, uri.password
          when /^1/
            conn.request :basic_auth, uri.user, uri.password
          else
            conn.request :authorization, :basic_auth, uri.user, uri.password
          end
        end

        conn.response :raise_error
        conn.request :retry, max: options[:retry_after_limit], interval: 0.05,
                             interval_randomness: 0.5, backoff_factor: 2,
                             exceptions: ['Faraday::Error', 'Timeout::Error'], methods: %i[delete get head options put post] if options[:retry_503]
        conn.adapter options[:adapter] || Faraday.default_adapter || :net_http
      end
    end
  end
end

module Hydra::AccessControlsEnforcement
  def escape_filter(key, value)
    [key, escape_value(value)].join(':')
  end

  def escape_value(value)
    RSolr.solr_escape(value).gsub(/ /, '\ ')
  end
end

ActiveFedora::SolrService.instance_eval do
  def self.query(query, args={})
    Rails.logger.warn "Calling ActiveFedora::SolrService.get without passing an explicit value for ':rows' is not recommended. You will end up with Solr's default (usually set to 10)\nCalled by #{caller[0]}" unless args.key?(:rows)
    method = args.delete(:method) || default_http_method
    if method == :get
      result = get(query, args)
    elsif method == :post
      result = post(query, args)
    end
    result['response']['docs'].map do |doc|
      ActiveFedora::SolrHit.new(doc)
    end
  end

  def self.post(query, args = {})
    args = args.merge(q: query, qt: 'standard')
    ActiveFedora::SolrService.instance.conn.post(select_path, data: args)
  end

  def self.default_http_method
    ActiveFedora.solr_config.fetch(:http_method, :post).to_sym
  end

  def self.count(query, args = {})
    args = args.merge(rows: 0)
    method = args.delete(:method) || default_http_method

    result = case method
	     when :get
	       get(query, args)
	     when :post
	       post(query, args)
	     else
	       raise "Unsupported HTTP method for querying SolrService (#{method.inspect})"
	     end
    result['response']['numFound'].to_i
  end
end

# Override to expand IP address ranges
Blacklight::AccessControls::Ability.class_eval do
  def read_groups(id)
    doc = permissions_doc(id)
    return [] if doc.nil?
    groups = Array(doc[self.class.read_group_field]).uniq
    groups = groups.map do |g|
      ip = IPAddr.new(g) rescue nil
      ip.present? ? ip.to_range.map(&:to_s) : g
    end.flatten.compact.uniq
    rg = download_groups(id) | groups
    Rails.logger.debug("[CANCAN] read_groups: #{rg.inspect}")
    rg
  end
end
