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
  class ClassOrderedRepositoryMigrator < RepositoryMigrator

    def migrate_objects(pids = nil, overwrite = false, skip_completed = false)
      @pids_whitelist = pids
      @overwrite = overwrite
      @skip_completed = skip_completed
      class_order.each do |klass|
        ::MediaObject.skip_callback(:save, :before, :update_dependent_properties!) if klass == ::MediaObject
        Parallel.map_with_index(gather_pids_for_class(klass), in_processes: parallel_processes, progress: "Migrating #{klass.to_s}") do |pid, i|
          next unless qualifying_pid?(pid, klass)
          # Let solr catch up
          ActiveFedora::SolrService.instance.conn.commit if (i % 100 == 0)
          ActiveFedora::SolrService.instance.conn.optimize if (i % 1000 == 0)
          remove_object(pid, klass) unless overwrite?
          migrate_object(source_object(pid), klass)
        end
        ::MediaObject.set_callback(:save, :before, :update_dependent_properties!) if klass == ::MediaObject
      end
      class_order.each do |klass|
        if second_pass_needed?(klass)
          Parallel.map_with_index(gather_pids_for_class(klass), in_processes: parallel_processes, progress: "Migrating #{klass.to_s} (second pass)") do |pid, i|
            next unless qualifying_pid?(pid, klass, :second_pass)
            # Let solr catch up
            ActiveFedora::SolrService.instance.conn.commit if (i % 100 == 0)
            ActiveFedora::SolrService.instance.conn.optimize if (i % 1000 == 0)
            migrate_object(source_object(pid), klass, :second_pass)
          end
        end
      end
      @report.reload
    end

    def migration_required?(pid, klass, method=:migrate)
      status_report = MigrationStatus.find_by(source_class: klass, f3_pid: pid, datastream: nil)
      status_report.nil? ||
        (status_report.status != 'completed' && status_report.status != 'waiting' && method == :migrate) ||
        (status_report.status != 'completed' && method == :second_pass) ||
        (!skip_completed? && overwrite? && method == :second_pass) ||
        (!skip_completed? && overwrite? && method == :migrate && status_report.status != 'waiting')
    end

    private

      def gather_pids_for_class(klass)
        # TODO make this faster by querying for @pids_whitelist instead of all objects
        query = "SELECT ?pid WHERE { ?pid <info:fedora/fedora-system:def/model#hasModel> <#{class_to_model_name(klass)}> }"
        # Query and filter using pids whitelist
        pids = FedoraMigrate.source.connection.sparql(query)["pid"].collect {|pid| pid.split('/').last}
        gathered_pids = @pids_whitelist.blank? ? pids : pids & @pids_whitelist

        if skip_completed?
          completed_pids = MigrationStatus.where(source_class: klass, status: 'completed', datastream: nil).pluck(:f3_pid)
          gathered_pids - completed_pids
        else
          gathered_pids
        end
      end

      def source_object(pid)
        FedoraMigrate.source.connection.find(pid)
      end

      def initialize_report(source)
        result = SingleObjectReport.new
        result.status = false
        @report.save(source.pid, result)
        result
      end

      def remove_object(pid, klass)
        target = klass.where(migrated_from_ssim: construct_migrate_from_uri(pid).to_s).first
        target.delete unless target.nil?
      end

      def cleanout_object!(target, klass)
        return nil unless target
        #target_id = target.id
        #target_class = target.class
        #success = target.delete.eradicate
        success = object_mover(klass).wipeout!(target)
        raise RuntimeError("Failed to cleanout object: #{target_id}") unless success
        #target_class.new(id: target_id)
        target
      end

      def overwrite?
        !!@overwrite
      end

      def skip_completed?
        !!@skip_completed
      end

      def migrate_object(source, klass, method=:migrate)
        result = initialize_report(source)
        status_record = MigrationStatus.find_or_create_by(source_class: klass.name, f3_pid: source.pid, datastream: nil)
        unless (status_record.status == 'failed') && (method == :second_pass)
          begin
            target = klass.where(migrated_from_ssim: construct_migrate_from_uri(source.pid).to_s).first
            if overwrite? && (method != :second_pass)
              target = cleanout_object!(target, klass)
              unless target.nil?
                MigrationStatus.where(f3_pid: status_record.f3_pid).delete_all
                status_record = MigrationStatus.find_or_create_by(source_class: klass.name, f3_pid: source.pid, datastream: nil)
              end
            end
            status_record.update_attributes status: method.to_s, log: nil
            options[:report] = @report.results[source.pid] = reload_single_item_report(source.pid) if method == :second_pass
            result.object = object_mover(klass).new(source, target, options).send(method)
            status_record.reload
            if status_record.status == "failed"
              result.status = false
            else
              status_record.update_attribute :f4_pid, result.object.id unless method == :second_pass
              result.status = true
            end
          rescue StandardError => e
            result.object = {exception: e.class.name, message: e.message, backtrace: e.backtrace[0..15]}
            status_record.update_attribute :log, %{#{e.class.name}: "#{e.message}"}
            result.status = false
          ensure
            status_record.update_attribute :status, end_status(result, method, klass)
            remove_object(source.pid, klass) if status_record.status == "failed"
            @report.save(source.pid, result)
          end
        end
      end

      def end_status(result, method, klass)
        if result.status
          if method == :migrate and second_pass_needed?(klass)
            return 'waiting'
          else
            return 'completed'
          end
        end
        return 'failed'
      end

      def second_pass_needed?(klass)
        object_mover(klass).instance_methods.include?(:second_pass)
      end

      def object_mover(klass)
        ("FedoraMigrate::" + klass.name.gsub(/::/,'') + "::ObjectMover").constantize
      end

      def class_order
        @options[:class_order]
      end

      def parallel_processes
        (@options[:parallel_processes] || (Parallel.processor_count - 2)).to_i
      end

      def qualifying_pid?(pid, klass, method=:migrate)
        name = pid.split(/:/).first
        name.match(namespace) && migration_required?(pid, klass, method)
      end

      def parse_model_name(object)
        model_uri = object.models.find {|m| m.start_with? "info:fedora/afmodel"}
        model_uri.nil? ? nil : model_uri[/afmodel:(.+?)$/, 1].gsub(/_/,'::')
      end

      def class_to_model_name(klass)
        "info:fedora/afmodel:#{klass.name.gsub(/(::)/, '_')}"
      end

      def construct_migrate_from_uri(pid)
        RDF::URI.new(FedoraMigrate.fedora_config.credentials[:url]) / "/objects/#{pid}"
      end

      def reload_single_item_report(pid)
        path = @report.path
        file = File.join(path, pid.tr(':', "_") + ".json")
        JSON.parse(File.read(file))
      end
  end
end
