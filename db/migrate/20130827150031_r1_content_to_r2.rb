class R1ContentToR2 < ActiveRecord::Migration
  def up
    ActiveFedora::Base.reindex_everything
    migration_path = File.join(Rails.root,'db/hydra')
    Hydra::Migrate::Dispatcher.migrate_all!(MediaObject, to: 'R2', path: migration_path) do |o,m,d|
      current = o.current_migration.blank? ? 'unknown version' : o.current_migration
      Rails.logger.info "Migrating #{o.class} #{o.pid} from #{current} to #{m[:to]}"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
