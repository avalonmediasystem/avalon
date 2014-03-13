require 'avalon/matterhorn_rtmp_url'

class R2ContentToR3 < ActiveRecord::Migration
  def up
    say_with_time("R2->R3") do
      prefix = Avalon::Configuration.lookup('fedora.namespace')
      ActiveFedora::Base.reindex_everything("pid~#{prefix}:*")
#      Derivative.find_each({'has_model_version_ssim' => 'R2'},{batch_size:5}) { |obj| derivative_to_r3(obj) }
      MasterFile.find_each({'has_model_version_ssim' => 'R2'},{batch_size:5}) { |obj| masterfile_to_r3(obj) }
      MediaObject.find_each({'has_model_version_ssim' => 'R2'},{batch_size:5}) { |obj| mediaobject_to_r3(obj) }
      Admin::Collection.find_each({'has_model_version_ssim' => 'R2'},{batch_size:5}) { |obj| collection_to_r3(obj) }
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def collection_to_r3(collection)
    say("Admin::Collection #{collection.pid}", :subitem)
    if ! collection.dropbox_directory_name
      collection.send(:create_dropbox_directory!)
    end
#    collection.media_objects.each { |mo| mediaobject_to_r3(mo) }
    collection.save_as_version('R3', validate: false)
  end

  def mediaobject_to_r3(mo)
    say("MediaObject #{mo.pid}", :subitem)
#    mo.parts_with_order.each { |mf| masterfile_to_r3(mf) }
    # The following two operations are handled by before_save callbacks
    # mo.populate_duration!
    # mo.update_permalink_and_dependents

    migrate_rights_metadata(mo)

    mo.save_as_version('R3', validate: false)
  end

  def masterfile_to_r3(mf)
    say("MasterFile #{mf.pid}", :subitem)
    workflow = Rubyhorn.client.instance_xml(mf.workflow_id)
    stream_base = workflow.stream_base.first rescue nil
    stream_base ||= Rubyhorn.client.me['org']['properties']['avalon.stream_base']
    raise 'Error: stream base must be set in the Matterhorn configuration' unless stream_base.present?

    mf.derivatives.each { |d| derivative_to_r3(d, stream_base) }
    file_location = mf.file_location
    mf.absolute_location = Avalon::FileResolver.new.path_to(file_location) rescue nil

    mf.set_workflow(nil) unless mf.workflow_name.present?

    add_display_aspect_ratio_to_masterfile(mf)

    mf.save_as_version('R3', validate: false)
  end

  def derivative_to_r3(d, stream_base)
    say("Derivative #{d.pid}", :subitem)
    if !d.absolute_location.present? and d.location_url.present?
      d.absolute_location = File.join(stream_base, Avalon::MatterhornRtmpUrl.parse(d.location_url).to_path) if stream_base
      d.save_as_version('R3', validate: false)
    end
  end

  def migrate_rights_metadata(mo)
    mo.read_users += find_user_exceptions(mo.rightsMetadata.ng_xml)
    mo.read_groups += find_group_exceptions(mo.rightsMetadata.ng_xml)
    exceptions = find_exceptions_node(mo.rightsMetadata.ng_xml)
    exceptions.remove if exceptions
  end

  def find_user_exceptions(xml)
    xml.xpath("//rm:access[@type='exceptions']/rm:machine/rm:person", {'rm' => 'http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1'}).map {|n| n.text }
  end

  def find_group_exceptions(xml)
    xml.xpath("//rm:access[@type='exceptions']/rm:machine/rm:group", {'rm' => 'http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1'}).map {|n| n.text }
  end

  def find_exceptions_node(xml)
    xml.xpath("//rm:access[@type='exceptions']", {'rm' => 'http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1'}).first
  end

  def add_display_aspect_ratio_to_masterfile(masterfile)
    if masterfile.is_video? && masterfile.display_aspect_ratio.blank? 
      begin
        workflow = Rubyhorn.client.instance_xml(masterfile.workflow_id)
        if workflow && (resolutions = workflow.streaming_resolution).any?
          ratio = resolutions.first
        end
      rescue
        # no workflow available, resort to using mediainfo on a derivative
        d = masterfile.derivatives.first
        if !d.nil? 
          d_info = Mediainfo.new d.absolute_location
          ratio = d_info.video_display_aspect_ratio
        end
      ensure
        if ratio.nil? 
          ratio = "4:3"
          logger.warn("#{masterfile.pid} aspect ratio not found - setting to default 4:3")
        end
        masterfile.display_aspect_ratio = ratio.split(/[x:]/).collect(&:to_f).reduce(:/).to_s 
      end
    end
  end
end
