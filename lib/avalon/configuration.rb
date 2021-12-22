# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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


module Avalon
  class Config
    def rehost(url, host=nil)
      if host.present?
        url.sub(%r{/localhost([/:])},"/#{host}\\1")
      else
        url
      end
    end

    def method_missing(sym, *args, &block)
      super(sym, *args, &block) unless @config.respond_to?(sym)
      @config.send(sym, *args, &block)
    end

    private
    class << self
      def coerce(value, method)
        value.nil? ? nil : value.send(method)
      end

      def read_avalon_url(v)
        return({}) if v.nil?
        avalon_url = Addressable::URI.parse(v)
        { 'host'=>avalon_url.host, 'port'=>avalon_url.port, 'protocol'=>avalon_url.scheme }
      end

      def write_avalon_url(v)
        Addressable::URI.build(scheme: v.fetch('protocol','http'), host: v['host'], port: v['port']).to_s
      end
    end

    def deep_compact(value)
      if value.is_a?(Hash)
        new_value = value.dup
        new_value.each_pair { |k,v|
          compact_value = deep_compact(v)
          if compact_value.nil?
            new_value.delete(k)
          else
            new_value[k] = compact_value
          end
        }
        new_value.empty? ? nil : new_value
      else
        (value.nil? or (value.respond_to?(:empty?) and value.empty?)) ? nil : value
      end
    end
  end

  Configuration = Config.new
end
