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
  class ReassignIdRelsExtDatastreamMover < RelsExtDatastreamMover
    # def post_initialize
    #   @target = ActiveFedora::Base.find(target.id)
    # rescue ActiveFedora::ObjectNotFoundError
    #   raise FedoraMigrate::Errors::MigrationError, "Target object was not found in Fedora 4. Did you migrate it?"
    # end

    def migrate
      migrate_statements
      migrate_whitelist
      # target.save
      report
    end
    
    def migrate_whitelist
      graph.statements.each do |stmt| 
        if predicate_whitelist.include?(stmt.predicate) 
          triple = [target.rdf_subject, stmt.predicate, stmt.object]
          target.ldp_source.graph << triple
          report << triple.join("--")
        end
      end
    end

    private

      def locate_object_id(id)
        return target if source.pid == id
        ActiveFedora::Base.where(identifier_ssim: id.downcase).first.try(:id)
      end

      def migrate_object(fc3_uri)
        obj_id = locate_object_id(fc3_uri.to_s.split('/').last)
        #FIXME raise error or return if obj_id.nil?
        RDF::URI.new(ActiveFedora::Base.id_to_uri(obj_id))
      end

      def predicate_blacklist
        [ActiveFedora::RDF::Fcrepo::Model.hasModel, "http://projecthydra.org/ns/relations#hasModelVersion"]
      end

      def predicate_whitelist
        ['http://projecthydra.org/ns/relations#hasPermalink']
      end
      
      def missing_object?(statement)
        return false if locate_object_id(statement.object.to_s.split('/').last).present?
        report << "could not migrate relationship #{statement.predicate} because #{statement.object} doesn't exist in Fedora 4" unless predicate_whitelist.include?(statement.predicate)
        true
      end

      # All the graph statements except hasModel and those with missing objects
      def statements
        graph.statements.reject { |stmt| predicate_blacklist.include?(stmt.predicate) || missing_object?(stmt) }
      end
  end
end
