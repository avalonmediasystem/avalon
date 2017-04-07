# Taken from https://github.com/projecthydra-labs/hyku/blob/master/lib/tasks/zookeeper.rake
namespace :zookeeper do
  desc 'Push solr configs into zookeeper'
  task upload: [:environment] do
    SolrConfigUploader.default.upload(Settings.solr.configset_source_path)
  end

  desc 'Create a collection'
  task create: [:environment] do
    collection_name = Blacklight.default_index.connection.uri.path.split(/\//).reject(&:empty?).last
    SolrCollectionCreator.new(collection_name).perform
  end

  desc 'Delete solr configs from zookeeper'
  task delete_all: [:environment] do
    SolrConfigUploader.default.delete_all
  end
end
