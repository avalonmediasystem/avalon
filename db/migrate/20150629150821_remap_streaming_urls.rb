class RemapStreamingUrls < ActiveRecord::Migration
  def up
    Derivative.find_each({},{batch_size:10}) do |d|
      d.set_streaming_locations!
      d.save!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
