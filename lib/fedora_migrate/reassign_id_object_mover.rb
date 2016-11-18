require 'fedora_migrate/reassign_id_target_constructor'
require 'fedora_migrate/reassign_id_rels_ext_datastream_mover'
require 'fedora_migrate/dublin_core_datastream_mover'
require 'fedora_migrate/inherited_rights_datastream_mover'

module FedoraMigrate
  class ReassignIdObjectMover < ObjectMover
    SinglePassReport = Struct.new(:id, :class, :content_datastreams, :rdf_datastreams, :permissions, :dates, :relationships)

    def results_report
      SinglePassReport.new.tap do |report|
        report.content_datastreams = []
        report.rdf_datastreams = []
      end
    end

    def complete_target
      after_object_migration
      save
      complete_report
    end

    def complete_report
      report.id = target.id
    end

    def target
      @target ||= FedoraMigrate::ReassignIdTargetConstructor.new(source).build
    end

    private

      def migrate_dublin_core
        return unless source.datastreams.keys.include?('DC')
        mover = FedoraMigrate::DublinCoreDatastreamMover.new(source.datastreams['DC'], target)
        mover.migrate
        # report.dc = mover.migrate
      end

      def migrate_inherited_rights
        return unless source.datastreams.keys.include?('inheritedRights')
        mover = FedoraMigrate::InheritedRightsDatastreamMover.new(source.datastreams['inheritedRights'], target)
        mover.migrate
        report.permissions += mover.migrate
      end

      def migrate_relationships
        report.relationships = FedoraMigrate::ReassignIdRelsExtDatastreamMover.new(source, target).migrate
      end
  end
end
