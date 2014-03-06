class R2ContentToR3 < ActiveRecord::Migration
  def up
    prefix = Avalon::Configuration.lookup('fedora.namespace')
    ActiveFedora::Base.reindex_everything("pid~#{prefix}:*")
    MediaObject.find_each({'has_model_version_ssim' => 'R2'},{batch_size:5}) do |mo|
      mediaobject_to_r3(mo)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def mediaobject_to_r3(mo)
    mo.parts_with_order.each { |mf| masterfile_to_r3(mf) }
    mo.populate_duration!
    mo.update_permalink_and_dependents
    mo.save_as_version('R3', validate: false)
  end

  def masterfile_to_r3(mf)
    workflow = Rubyhorn.client.instance_xml(mf.workflow_id)
    stream_base = workflow.stream_base.first rescue nil
    mf.derivatives.each { |d| derivative_to_r3(mf, stream_base) }
    file_location = mf.file_location
    mf.absolute_location = Avalon::FileResolver.new.path_to(file_location) rescue nil
    mf.save_as_version('R3', validate: false)
  end

  def derivative_to_r3(d, stream_base)
    d.absolute_location = File.join(stream_base, Avalon::MatterhornRtmpUrl.parse(d.location_url).to_path) if stream_base
    d.save_as_version('R3', validate: false)
  end
end
