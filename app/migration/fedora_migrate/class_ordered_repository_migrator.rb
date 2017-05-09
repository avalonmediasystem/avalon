# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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

    attr_accessor :klass

    def migrate_objects(pids = nil)
      @pids_whitelist = pids
      class_order.each do |klass|
        @klass = klass
        klass.class_eval do
          # We don't really need multiple true but there is a bug with indexing single valued URI objects
          property :migrated_from, predicate: RDF::URI("http://www.w3.org/ns/prov#wasDerivedFrom"), multiple: true do |index|
            index.as :symbol
          end
        end
        source_objects(klass) do |object|
          @source = object
          migrate_current_object
        end
      end
      class_order.each do |klass|
        @klass = klass
        if second_pass_needed?
          source_objects(klass) do |object|
            @source = object
            migrate_object(:second_pass)
          end
        end
      end
      report.reload
    end

    def migrate_relationships
      # return "Relationship migration skipped because migrator invoked in single pass mode." if single_pass?
      super
    end

    def migrate_current_object
      return unless migration_required?
      initialize_report
      migrate_object
    end

    def migration_required?
      status_report = MigrationStatus.find_by(source_class: klass, f3_pid: source.pid, datastream: nil)
      status_report.nil? || (status_report.status != 'completed')
    end
    
    def source_objects(klass, &block)
      gather_pids_for_class(klass).each do |pid|
        obj = FedoraMigrate.source.connection.find(pid)
        block.call(obj) if qualifying_object(obj)
      end
    end

    private

      def gather_pids_for_class(klass)
        query = "SELECT ?pid WHERE { ?pid <info:fedora/fedora-system:def/model#hasModel> <#{class_to_model_name(klass)}> }"
        # Query and filter using pids whitelist
        pids = FedoraMigrate.source.connection.sparql(query)["pid"].collect {|pid| pid.split('/').last}
        @pids_whitelist.blank? ? pids : pids & @pids_whitelist
      end

      def migrate_object(method=:migrate)
        status_record = MigrationStatus.find_or_create_by(source_class: klass.name, f3_pid: source.pid, datastream: nil)
        unless (status_record.status == 'failed') && (method == :second_pass)
          begin
            status_record.update_attributes status: method.to_s, log: nil
            target = klass.where(migrated_from_ssim: construct_migrate_from_uri(source).to_s).first
            options[:report] = report.reload[source.pid]
            result.object = object_mover.new(source, target, options).send(method)
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
            status_record.update_attribute :status, end_status(method)
            report.save(source.pid, result)
          end
        end
      end
      
      def end_status(method)
        if result.status
          if method == :migrate and second_pass_needed?
            return 'waiting'
          else
            return 'completed'
          end
        end
        return 'failed'
      end
      
      def second_pass_needed?
        object_mover.instance_methods.include?(:second_pass)
      end

      def object_mover
        ("FedoraMigrate::" + klass.name.gsub(/::/,'') + "::ObjectMover").constantize
      end

      def class_order
        @options[:class_order]
      end

      # def single_pass?
      #   !!@options[:single_pass]
      # end
      #
      # def reassign_ids?
      #   !!@options[:reassign_ids]
      # end

      #def qualifying_object(object, klass)
      #  name = object.pid.split(/:/).first
      #  return object if (name.match(namespace) && object.models.include?("info:fedora/afmodel:#{klass.name.gsub(/(::)/, '_')}"))
      #end

      def parse_model_name(object)
        model_uri = object.models.find {|m| m.start_with? "info:fedora/afmodel"}
        model_uri.nil? ? nil : model_uri[/afmodel:(.+?)$/, 1].gsub(/_/,'::')
      end

      def class_to_model_name(klass)
        "info:fedora/afmodel:#{klass.name.gsub(/(::)/, '_')}"
      end

      def construct_migrate_from_uri(source)
        RDF::URI.new(FedoraMigrate.fedora_config.credentials[:url]) / "/objects/#{source.pid}"
      end
  end
end
