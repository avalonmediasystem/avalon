module FedoraMigrate
  class ClassOrderedRepositoryMigrator < RepositoryMigrator

    attr_accessor :klass

    def migrate_objects
      class_order.each do |klass|
        @klass = klass
        klass.class_eval do
          property :migrated_from, predicate: RDF::URI("http://avalonmediasystem.org/ns/migration#migratedFrom"), multiple: false do |index|
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
      MigrationStatus.find_by(source_class: klass, f3_pid: source.pid, datastream: nil).nil?
    end
    
    def source_objects(klass)
      @source_objects ||= FedoraMigrate.source.connection.search(nil).collect { |o| qualifying_object(o, klass) }.compact
    end

    private

      def migrate_object(method=:migrate)
        status_record = MigrationStatus.find_or_create_by(source_class: klass.name, f3_pid: source.pid, datastream: nil)
        begin
          status_record.update_attribute :status, method.to_s
          target = klass.where(migrated_from_tesim: source.pid).first
          options[:report] = report.reload[source.pid]
          result.object = object_mover.new(source, target, options).send(method)
          status_record.update_attribute :f4_pid, result.object.id
          result.status = true
        rescue StandardError => e
          result.object = {exception: e.class.name, message: e.message, backtrace: e.backtrace[0..15]}
          status_record.update_attribute :log, %{#{e.class.name}: "#{e.message}"}
          result.status = false
        ensure
          status_record.update_attribute :status, end_status(method)
          report.save(source.pid, result)
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
  end
end
