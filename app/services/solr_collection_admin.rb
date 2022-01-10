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
