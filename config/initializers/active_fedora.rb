ActiveFedora::Base.class_eval do
  has_metadata name: 'DC', type: DublinCoreDocument
end

ActiveFedora::QueryMethods.module_eval do
    def extending(*modules, &block)
      if modules.any? || block
        spawn.extending!(*modules, &block)
      else
        self
      end
    end
end
