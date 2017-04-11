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

    def migrate_objects
      class_order.each do |klass|
        @klass = klass
        klass.class_eval do
          property :migrated_from, predicate: RDF::URI("http://www.w3.org/ns/prov#wasDerivedFrom"), multiple: false do |index|
            index.as :stored_searchable
          end
        end
        @source_objects = nil
        source_objects(klass).each do |object|
          @source = object
          migrate_current_object
        end
      end
      class_order.each do |klass|
        @klass = klass
        if second_pass_needed?
          @source_objects = nil
          source_objects(klass).each do |object|
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
    
    def source_objects(klass)
      @source_objects ||= FedoraMigrate.source.connection.search(nil).collect { |o| qualifying_object(o, klass) }.compact
    end

    private

      def migrate_object(method=:migrate)
        status_record = MigrationStatus.find_or_create_by(source_class: klass.name, f3_pid: source.pid, datastream: nil)
        unless (status_record.status == 'failed') && (method == :second_pass)
          begin
            status_record.update_attributes status: method.to_s, log: nil
            target = klass.where(migrated_from_tesim: construct_migrate_from_uri(source).to_s).first
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

      def qualifying_object(object, klass)
        name = object.pid.split(/:/).first
        return object if (name.match(namespace) && object.models.include?("info:fedora/afmodel:#{klass.name.gsub(/(::)/, '_')}"))
      end

      def construct_migrate_from_uri(source)
        RDF::URI.new(FedoraMigrate.fedora_config.credentials[:url]) / "/objects/#{source.pid}"
      end
  end
end
