# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

def wipeout_fedora
  ActiveFedora::Cleaner.clean!
end

def wipeout_solr(solr)
  solr.delete_by_query('*:*')
  solr.commit
end

def wipeout_redis
  Sidekiq.redis(&:flushdb)
end

def wipeout_db
  [MigrationStatus, ActiveAnnotations::Annotation, Bookmark, Search, ApiToken, Course,
   IngestBatch, PlaylistItem, Playlist, RoleMap, StreamToken, User].each(&:delete_all)
end

namespace :avalon do
  namespace :wipeout do
    desc "Reset fedora to empty state"
    task fedora: :environment do
      wipeout_fedora
    end

    desc "Reset solr to empty state"
    task solr: :environment do
      wipeout_solr(ActiveFedora.solr.conn)
    end

    desc "Reset redis to empty state"
    task redis: :environment do
      wipeout_redis
    end

    desc "Reset db to empty state"
    task db: :environment do
      wipeout_db
    end
  end

  desc "Reset Fedora, Solr, DB, and Redis to empty state"
  task :wipeout => :environment do
    unless ENV['CONFIRM'] == 'yes'
      $stderr.puts <<-EOC
WARNING: This process will destroy all data in:

DB: All tables
Fedora: #{ActiveFedora.fedora.build_connection.http.url_prefix}
Solr: #{ActiveFedora.solr_config[:url]}
Redis: #{Sidekiq.redis { |c| c._client.options.values_at(:host, :port, :db).join(':') }}

Please run `rake avalon:wipeout CONFIRM=yes` to confirm.
EOC
      exit 1
    end

    ['fedora','solr','redis','db'].each do |component|
      Rake::Task["avalon:wipeout:#{component}"].invoke
    end
  end
end
