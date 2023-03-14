# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

class SolrCollectionCreator
  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def perform
    unless collection_exists? name
      client.get '/solr/admin/collections', params: collection_options.merge(action: 'CREATE', name: name)
    end
  end

  class CollectionOptions
    attr_reader :settings

    def initialize(settings = {})
      @settings = settings
    end

    ##
    # @example Camel-casing
    #   { replication_factor: 5 } # => { "replicationFactor" => 5 }
    # @example Blank-rejecting
    #   { emptyValue: '' } #=> { }
    # @example Nested value-flattening
    #   { collection: { config_name: 'x' } } # => { 'collection.configName' => 'x' }
    def to_h
      Hash[*settings.map { |k, v| transform_entry(k, v) }.flatten].reject { |_k, v| v.blank? }.symbolize_keys
    end

    private

      def transform_entry(k, v)
        case v
        when Hash
          v.map do |k1, v1|
            ["#{transform_key(k)}.#{transform_key(k1)}", v1]
          end
        else
          [transform_key(k), v]
        end
      end

      def transform_key(k)
        k.to_s.camelize(:lower)
      end
  end

  private

    def client
      ActiveFedora.solr.conn
    end

    def collection_options
      CollectionOptions.new(Settings.solr.collection_options.to_hash).to_h
    end

    def collection_exists?(name)
      response = client.get '/solr/admin/collections', params: { action: 'LIST' }
      collections = response['collections']

      collections.include? name
    end

    def collection_url(name)
      normalized_uri = if Settings.solr.url.ends_with?('/')
                         Settings.solr.url
                       else
                         "#{Settings.solr.url}/"
                       end

      uri = Addressable::URI.normalized_encode(normalized_uri) + name

      uri.to_s
    end
end
