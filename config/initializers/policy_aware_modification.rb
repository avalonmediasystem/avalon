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
    str.gsub(/([+\-&|!\(\)\{\}\[\]\^"'~\*\?:\\\/])/, '\\\\\1')
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
