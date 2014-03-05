# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

class R1ContentToR2 < ActiveRecord::Migration
  def up
    prefix = Avalon::Configuration.lookup('fedora.namespace')
    ActiveFedora::Base.reindex_everything("pid~#{prefix}:*")
    if MediaObject.count > 0
      migration_path = File.join(Rails.root,'db/hydra')
      Hydra::Migrate::Dispatcher.migrate_all!(MediaObject, to: 'R2', path: migration_path) do |o,m,d|
        current = o.current_migration.blank? ? 'unknown version' : o.current_migration
        Rails.logger.info "Migrating #{o.class} #{o.pid} from #{current} to #{m[:to]}"
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
