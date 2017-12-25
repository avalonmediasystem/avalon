class SolrCollectionAdmin

  def initialize
    base, @collection = ActiveFedora.solr_config[:url].reverse.split(/\//,2).reverse.collect(&:reverse)
    @conn = Faraday.new(url: base)
  end

  def backup(location, opts={})
    opts[:optimize] = true unless opts.key?(:optimize)
    optimize = !!opts[:optimize]
    timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    backup_name = "#{@collection}_backup_#{timestamp}"
    @conn.get("#{@collection}/update", optimize: 'true') if optimize
    response = @conn.get('admin/collections', action: 'BACKUP', name: backup_name, collection: @collection, location: location, wt: 'json')
    response.body
  end

  def restore(location, opts={})
    raise ArgumentError, "Required parameter `name` missing or invalid" unless opts[:name]
    params = { action: 'RESTORE', collection: @collection, location: location, wt: 'json' }.merge(opts)
    response = @conn.get('admin/collections', params)
    response.body
  end

end
