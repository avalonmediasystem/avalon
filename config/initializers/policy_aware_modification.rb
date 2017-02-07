require 'active-fedora'

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
end
