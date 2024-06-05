baseparts = 2 + [(Noid::Rails.config.template.gsub(/\.[rsz]/, '').length.to_f / 2).ceil, 4].min
baseurl = "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}"
ActiveFedora::Base.translate_uri_to_id = lambda do |uri|
                                           uri.to_s.sub(baseurl, '').split('/', baseparts).last
                                         end
ActiveFedora::Base.translate_id_to_uri = lambda do |id|
                                           "#{baseurl}/#{Noid::Rails.treeify(id).sub(/\/+$/, '')}"
                                         end
ActiveFedora::Base.logger = Rails.logger

# ActiveFedora 14.x+ does not set these by default for some reason so need to set them here
# Without these set AF::File subclasses like StructuralMetadata will include the btree in their ids
# (e.g. ab/cd/ef/gh/abcdefghi/structuralMetadata) which messes up SpeedyAF (and probably other things)
ActiveFedora::File.translate_uri_to_id = ActiveFedora::Base.translate_uri_to_id
ActiveFedora::File.translate_id_to_uri = ActiveFedora::Base.translate_id_to_uri

# ActiveModel::Dirty's internals were substantially rewritten in Rails 6 making the following monkey-patch potentially unnecessary.
# We will need to test this throroughly to ensure it is safe to remove.
#
## Monkey-patch to short circuit ActiveModel::Dirty which attempts to load the whole master files ordered list when calling nodes_will_change!
## This leads to a stack level too deep exception when attempting to delete a master file from a media object on the manage files step.
## See https://github.com/samvera/active_fedora/pull/1312/commits/7c8bbbefdacefd655a2ca653f5950c991e1dc999#diff-28356c4daa0d55cbaf97e4269869f510R100-R103
#ActiveFedora::Aggregation::ListSource.class_eval do
#  def attribute_will_change!(attr)
#    return super unless attr == 'nodes'
#    attributes_changed_by_setter[:nodes] = true
#  end
#end

# Override to avoid deprecation warning.  Remove this monkey-patch whenever Avalon upgrades to a version of LDP which has this fix.
Ldp::Response.class_eval do
  def content_disposition_filename
    filename = content_disposition_attributes['filename']
    ::RDF::URI.decode(filename) if filename
  end
end

# Overrides that ensure AccessControl objects are marked dirty when read/edit/discover groups/users are changed and autosave if dirty
# This fixes a timing bug where AccessControl objects are saved in an after_save callback which runs after normal indexing occurs
# See https://github.com/avalonmediasystem/avalon/issues/5140

# Override contained_rdf_sources to ensure AccessControl objects get autosaved when dirty
ActiveFedora::Base.class_eval do
  private
    def save_contained_resources
      contained_resources.changed.each do |_, resource|
        resource.save
      end
      save_access_control_resources
    end

    def save_access_control_resources
      access_control_sources.changed.each do |_, resource|
	resource.save
      end
    end

    def access_control_sources
      @access_control_sources ||= ActiveFedora::AssociationHash.new(self, access_control_reflections)
    end

    def access_control_reflections
      self.class.reflect_on_all_associations(:belongs_to).select { |_, reflection| reflection.klass <= Hydra::AccessControl }
    end
end

# Enable dirty tracking for the permissions attribute
Rails.application.config.to_prepare do
  Hydra::AccessControl.define_attribute_methods :permissions
end

# Override set_entities to notify ActiveModel::Dirty dirty tracking that the permissions attribute is changing
Hydra::AccessControls::Permissions.module_eval do
  private
      # @param [Symbol] permission either :discover, :read or :edit
      # @param [Symbol] type either :person or :group
      # @param [Array<String>] values Values to set
      # @param [Array<String>] changeable Values we are allowed to change
      def set_entities(permission, type, values, changeable)
        (changeable - values).each do |entity|
          for_destroy = search_by_type_and_mode(type, permission_to_uri(permission)).select { |p| p.agent_name == entity }
          access_control.permissions_will_change!
          permissions.delete(for_destroy)
        end

        values.each do |agent_name|
          exists = search_by_type_and_mode(type, permission_to_uri(permission)).select { |p| p.agent_name == agent_name }
          access_control.permissions_will_change!
          permissions.build(name: agent_name, access: permission.to_s, type: type) unless exists.present?
        end
      end
end
# End of overrides for AccessControl dirty tracking and autosaving

# Override ActiveFedora::Associations::Builder::Orders::FixFirstLast to remove attempts to set first and last from list_source on saving
ActiveFedora::Associations::Builder::Orders::FixFirstLast.module_eval do
  def save(*args)
    super
  end

  def save!(*args)
    super
  end
end

# Override to add handling of :master_files associations
# This override allows setting the hasPart triples of the master_files association manually
# without going through the indirectly_contains association writer.
# Without this override new hasPart triples signaled as changes via attribute_will_change! are not
# detected as changes for the ChangeSet and are not persisted.
ActiveFedora::ChangeSet.class_eval do
    # @return [Hash<RDF::URI, RDF::Queryable::Enumerator>] hash of predicate uris to statements
    def changes
      @changes ||= changed_attributes.each_with_object({}) do |key, result|
        if object.association(key.to_sym).is_a? ActiveFedora::Associations::Association
          # ActiveFedora::Reflection::RDFPropertyReflection
          predicate = object.association(key.to_sym).reflection.predicate
          values = graph.query({ subject: object.rdf_subject, predicate: predicate })
          result[predicate] = values if predicate.present?
        elsif object.class.properties.keys.include?(key)
          predicate = graph.reflections.reflect_on_property(key).predicate
          results = graph.query({ subject: object.rdf_subject, predicate: predicate })
          new_graph = child_graphs(results.map(&:object))
          results.each do |res|
            new_graph << res
          end
          result[predicate] = new_graph
        elsif key == 'type'.freeze
          # working around https://github.com/ActiveTriples/ActiveTriples/issues/122
          predicate = ::RDF.type
          result[predicate] = graph.query({ subject: object.rdf_subject, predicate: predicate }).select do |statement|
            !statement.object.to_s.start_with?("http://fedora.info/definitions/v4/repository#", "http://www.w3.org/ns/ldp#")
          end
        elsif object.local_attributes.include?(key)
          raise "Unable to find a graph predicate corresponding to the attribute: \"#{key}\""
        end
      end
    end
end

ActiveFedora::Reflection::IndirectlyContainsReflection.class_eval do
  def predicate
    options[:has_member_relation] || ::RDF::Vocab::LDP.contains
  end
end
