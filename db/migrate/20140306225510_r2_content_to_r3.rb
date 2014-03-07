class R2ContentToR3 < ActiveRecord::Migration
  def up
    say_with_time("R2->R3") do
      prefix = Avalon::Configuration.lookup('fedora.namespace')
      ActiveFedora::Base.reindex_everything("pid~#{prefix}:*")
      Admin::Collection.find_each({'has_model_version_ssim' => 'R2'},{batch_size:5}) do |collection|
        collection_to_r3(collection)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def collection_to_r3(collection)
    say("Admin::Collection #{collection.pid} #{collection.current_migration}->R3", :subitem)
    collection.media_objects.each { |mo| mediaobject_to_r3(mo) }
    collection.save_as_version('R3')
  end

  def mediaobject_to_r3(mo)
    say("MediaObject #{mo.pid} #{mo.current_migration}->R3", :subitem)
    mo.parts_with_order.each { |mf| masterfile_to_r3(mf) }
    # The following two operations are handled by before_save callbacks
    # mo.populate_duration!
    # mo.update_permalink_and_dependents
    mo.save_as_version('R3', validate: false)
  end

  def masterfile_to_r3(mf)
    say("MasterFile #{mf.pid} #{mf.current_migration}->R3", :subitem)
    workflow = Rubyhorn.client.instance_xml(mf.workflow_id)
    stream_base = workflow.stream_base.first rescue nil
    mf.derivatives.each { |d| derivative_to_r3(d, stream_base) }
    file_location = mf.file_location
    mf.absolute_location = Avalon::FileResolver.new.path_to(file_location) rescue nil
    mf.save_as_version('R3', validate: false)
  end

  def derivative_to_r3(d, stream_base)
    say("Derivative #{d.pid} #{d.current_migration}->R3", :subitem)
    d.absolute_location = File.join(stream_base, Avalon::MatterhornRtmpUrl.parse(d.location_url).to_path) if stream_base
    d.save_as_version('R3', validate: false)
  end
end
