module FedoraMigrate
  module MediaObject
    class MasterFileAggregationMover < ObjectMover
      def migrate
        return false unless target.migrated_from.present?
        master_files = ::MasterFile.where(isPartOf_ssim: target.id)
        if source.datastreams.has_key?('sectionsMetadata')
          sections_md = Nokogiri::XML(source.datastreams['sectionsMetadata'].content)
          old_pid_order = sections_md.xpath('fields/section_pid').collect(&:text)
          target.ordered_master_files = master_files.sort do |a,b|
            old_pid_order.index(a.migrated_from) <=> old_pid_order.index(b.migrated_from)
          end
        else
          target.ordered_master_files = master_files
        end
        target.save
        master_files.collect(&:id)
      end
    end
  end
end
