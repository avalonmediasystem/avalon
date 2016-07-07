class ConvertAnnotationsToClips < ActiveRecord::Migration
  def up
    execute("update annotations set type='AvalonClip' where type is null")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
