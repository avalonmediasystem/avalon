#FIXME autoload these elsewhere so this class doesn't need to know all of the object movers explicitly
require 'fedora_migrate/simple_xml_datastream_mover'
require 'fedora_migrate/admin_collection/object_mover'
require 'fedora_migrate/media_object/object_mover'

module FedoraMigrate
  class ClassOrderedRepositoryMigrator < RepositoryMigrator

    attr_accessor :klass

    def migrate_objects
      class_order.each do |klass|
        @klass = klass
        @source_objects = nil
        source_objects(klass).each do |object|
          @source = object
          migrate_current_object
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

    def source_objects(klass)
      @source_objects ||= FedoraMigrate.source.connection.search(nil).collect { |o| qualifying_object(o, klass) }.compact
    end

    private

      def migrate_object
        result.object = object_mover.new(source, nil, options).migrate
        result.status = true
      rescue StandardError => e
        result.object = e.inspect
        result.status = false
      ensure
        report.save(source.pid, result)
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
  end
end
