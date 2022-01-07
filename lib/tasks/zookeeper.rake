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

# Taken from https://github.com/projecthydra-labs/hyku/blob/master/lib/tasks/zookeeper.rake

namespace :zookeeper do
  desc 'Push solr configs into zookeeper'
  task upload: [:environment] do
    require 'avalon/solr_config_uploader'
    Avalon::SolrConfigUploader.default.upload(Settings.solr.configset_source_path)
  end

  desc 'Create a collection'
  task create: [:environment] do
    collection_name = Blacklight.default_index.connection.uri.path.split(/\//).reject(&:empty?).last
    SolrCollectionCreator.new(collection_name).perform
  end

  desc 'Delete solr configs from zookeeper'
  task delete_all: [:environment] do
    Avalon::SolrConfigUploader.default.delete_all
  end
end
