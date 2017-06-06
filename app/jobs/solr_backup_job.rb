class SolrBackupJob < ActiveJob::Base
  queue_as :solr_backup

  def perform(location = '/data/backup')
    SolrCollectionAdmin.new.backup(location)
  end
end
