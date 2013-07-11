module Hydra
  module ModelMixins
    module HybridDelegator

      extend ActiveSupport::Concern

      module ClassMethods
        def delegate(*methods)
          options = methods.last
          if options.include?(:at) || options.include?(:unique)
            ActiveFedora::Base.method(:delegate).unbind.bind(self).call(*methods)
          else
            Module.method(:delegate).unbind.bind(self).call(*methods)
          end
        end
      end
    end
  end
end