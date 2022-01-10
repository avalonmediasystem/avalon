# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

module FedoraMigrate
  class ReassignIdObjectMover < ObjectMover
    SinglePassReport = Struct.new(:id, :class, :content_datastreams, :rdf_datastreams, :permissions, :dates, :relationships)

    def results_report
      SinglePassReport.new.tap do |report|
        report.content_datastreams = []
        report.rdf_datastreams = []
      end
    end

    def prepare_target
      target.migrated_from = [construct_migrate_from_uri(source)]
      super
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

    def self.wipeout!(obj)
      return false if obj.new_record?
      obj.access_control.destroy if obj.respond_to?(:access_control)
      obj.attached_files.values.each do |file|
        next if file.new_record?
        file.destroy
        file.eradicate
      end
      obj.reload
      obj.resource.clear
      self.empty?(obj)
    end

    def self.empty?(obj)
      obj.resource.blank? &&
      (!obj.respond_to?(:access_control) || obj.access_control.blank?) &&
      obj.attached_files.values.all?(&:blank?)
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
        report.permissions ||= []
        report.permissions += mover.migrate
      end

      def migrate_relationships
        report.relationships = FedoraMigrate::ReassignIdRelsExtDatastreamMover.new(source, target).migrate
      end

      def migrate_permalink
        permalink_value = target.ldp_source.graph.find{|stmt| stmt.predicate == "http://projecthydra.org/ns/relations#hasPermalink"}.object.to_s rescue nil
        return unless permalink_value
        target.permalink = permalink_value 
      end

      def construct_migrate_from_uri(source)
        RDF::URI.new(FedoraMigrate.fedora_config.credentials[:url]) / "/objects/#{source.pid}"
      end
  end
end
