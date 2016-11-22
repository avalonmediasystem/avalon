module FedoraMigrate
  class ReassignIdRelsExtDatastreamMover < RelsExtDatastreamMover
    # def post_initialize
    #   @target = ActiveFedora::Base.find(target.id)
    # rescue ActiveFedora::ObjectNotFoundError
    #   raise FedoraMigrate::Errors::MigrationError, "Target object was not found in Fedora 4. Did you migrate it?"
    # end

    def migrate
      migrate_statements
      # target.save
      report
    end

    private

      def locate_object(id)
        return target if source.pid == id
        ActiveFedora::Base.where(identifier_ssim: id).first
      end

      def migrate_object(fc3_uri)
        obj = locate_object(fc3_uri.to_s.split('/').last)
        #FIXME raise error or return if obj.nil?
        RDF::URI.new(ActiveFedora::Base.id_to_uri(obj.id))
      end

      def missing_object?(statement)
        return false if locate_object(statement.object.to_s.split('/').last).present?
        report << "could not migrate relationship #{statement.predicate} because #{statement.object} doesn't exist in Fedora 4"
        true
      end

      # All the graph statements except hasModel and those with missing objects
      def statements
        blacklisted_predicates = [ActiveFedora::RDF::Fcrepo::Model.hasModel, "http://projecthydra.org/ns/relations#hasModelVersion"]
        graph.statements.reject { |stmt| blacklisted_predicates.include?(stmt.predicate) || missing_object?(stmt) }
      end
  end
end
