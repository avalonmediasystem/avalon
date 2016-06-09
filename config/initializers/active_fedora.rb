ActiveFedora::Base.class_eval do
  has_metadata name: 'DC', type: DublinCoreDocument
end

#Added for Kaminari paging
ActiveFedora::QueryMethods.module_eval do
    def extending(*modules, &block)
      if modules.any? || block
        spawn.extending!(*modules, &block)
      else
        self
      end
    end
end

#Cherry-picked 9cf316b71e78e65d95bfe1fa8ce93373da1a7305
ActiveFedora::Associations::CollectionProxy.class_eval do
      def scope
        @association.scope
      end
      alias spawn scope
end
