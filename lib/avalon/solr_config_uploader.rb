# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

# Upload solr configuration from the local filesystem into the zookeeper configs path for solr
# Taken from https://github.com/projecthydra-labs/hyku/blob/master/app/services/solr_config_uploader.rb
require 'zk'

module Avalon
  class SolrConfigUploader
    attr_reader :collection_path

    ##
    # Build a new SolrConfigUploader using the application-wide settings
    def self.default
      new(Settings.solr.configset)
    end

    def initialize(collection_path)
      @collection_path = collection_path
    end

    def upload(upload_directory)
      with_client do |zk|
        salient_files(upload_directory).each do |file|
          zk.create(zookeeper_path_for_file(file), file.read, or: :set)
        end
      end
    end

    def delete_all
      with_client do |zk|
        zk.rm_rf(zookeeper_path)
      end
    end

    def get(path)
      with_client do |zk|
        zk.get(zookeeper_path(path)).first
      end
    end

    private

      def zookeeper_path_for_file(file)
        zookeeper_path(File.basename(file.path))
      end

      def zookeeper_path(*path)
        "/#{([collection_path] + path).compact.join('/')}"
      end

      def salient_files(config_dir)
        return to_enum(:salient_files, config_dir) unless block_given?

        Dir.new(config_dir).each do |file_name|
          full_path = File.expand_path(file_name, config_dir)

          next unless File.file? full_path

          yield File.new(full_path)
        end
      end

      def with_client(&block)
        ensure_chroot!

        ZK.open(connection_str, &block)
      end

      def connection_str
        Settings.zookeeper.connection_str
      end

      def ensure_chroot!
        raise ArgumentError, 'Zookeeper connection string must include a chroot path' unless connection_str =~ %r{/[^/]}
      end
  end
end
