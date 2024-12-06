RSolr::Client.class_eval do
  def build_request path, opts
    raise "path must be a string or symbol, not #{path.inspect}" unless [String,Symbol].include?(path.class)
    path = path.to_s
    opts[:proxy] = proxy unless proxy.nil?
    # Avalon can produce requests that are too large for :get.
    # Override method to use configurable http method to avoid
    # having to override every instance that calls RSolr directly.
    opts[:method] ||= ActiveFedora::SolrService.default_http_method
    raise "The :data option can only be used if :method => :post" if opts[:method] != :post and opts[:data]
    opts[:params] = params_with_wt(opts[:params])
    query = RSolr::Uri.params_to_solr(opts[:params]) unless opts[:params].empty?
    opts[:query] = query
    if opts[:data].is_a? Hash
      opts[:data] = RSolr::Uri.params_to_solr opts[:data]
      opts[:headers] ||= {}
      opts[:headers]['Content-Type'] ||= 'application/x-www-form-urlencoded; charset=UTF-8'
    end
    opts[:path] = path
    opts[:uri] = base_uri.merge(path.to_s + (query ? "?#{query}" : "")) if base_uri

    opts
  end
end