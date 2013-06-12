require 'active_support/concern'

module Avalon::ManagerAssociation
  extend ActiveSupport::Concern

  included do
    class_eval do
      def self.find_all_by_manager_id( id )
        where(:manager_ids_facet => id.to_s)
      end
    end
  end


  module InstanceMethods
    
    def to_solr(solr_doc = Hash.new, opts = {})
      map = Solrizer::FieldMapper::Default.new
      solr_doc[ map.solr_name(:manager_ids, :string, :facetable) ] = self.managers.map(&:id)
      super(solr_doc)
    end

    def managers
      return [] unless relationships(:has_member).present?
      @managers ||= User.find(relationships(:has_member).map{|m| m.to_s.delete('info:fedora/').to_i })
    end

    def managers=( users )
      @managers = nil
      clear_relationship :has_member
      users.each do |user|
        self.add_relationship(:has_member,  RDF::Literal.new("info:fedora/#{user.id}"))
      end
    end
  end

end