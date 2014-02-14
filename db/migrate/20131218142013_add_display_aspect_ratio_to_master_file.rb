class AddDisplayAspectRatioToMasterFile < ActiveRecord::Migration
  def up
    MasterFile.find_each({},{batch_size:5}) do |masterfile|
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
            logger.warn("#{masterfile.pid} aspect ratio not found")
          else
            masterfile.display_aspect_ratio = ratio.split(/[x:]/).collect(&:to_f).reduce(:/).to_s 
            masterfile.save(validate: false)
          end
        end
      end
    end
  end
end
