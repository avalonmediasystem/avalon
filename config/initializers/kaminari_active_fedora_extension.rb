module Kaminari
#  module ActiveFedoraExtension
#    extend ActiveSupport::Concern
#
#    module ClassMethods
#      # Future subclasses will pick up the model extension
#      def inherited(kls) #:nodoc:
#        super
#        kls.send(:include, Kaminari::ActiveFedoraModelExtension) if kls.superclass == ::ActiveFedora::Base
#      end
#    end
#
#    included do
#      # Existing subclasses pick up the model extension as well
#      self.descendants.each do |kls|
#        kls.send(:include, Kaminari::ActiveFedoraModelExtension) if kls.superclass == ::ActiveFedora::Base
#      end
#    end
#  end
#
  module ActiveFedoraModelExtension
    extend ActiveSupport::Concern

    included do
      self.send(:include, Kaminari::ConfigurationMethods)

      # Fetch the values at the specified page number
      #   Model.page(5)
      eval <<-RUBY
        def self.#{Kaminari.config.page_method_name}(num = nil)
          limit(default_per_page).offset(default_per_page * ((num = num.to_i - 1) < 0 ? 0 : num)).extending do
            include Kaminari::ActiveFedoraRelationMethods
            include Kaminari::PageScopeMethods
          end
        end
      RUBY
    end
  end

  module ActiveFedoraRelationMethods
    def entry_name
      model_name.human.downcase
    end

    def reset #:nodoc:
      @total_count = nil
      super
    end

    def total_count(column_name = :all, options = {}) #:nodoc:
      # #count overrides the #select which could include generated columns referenced in #order, so skip #order here, where it's irrelevant to the result anyway
      @total_count ||= begin
#        c = except(:offset, :limit, :order)

        # Remove includes only if they are irrelevant
 #       c = c.except(:includes) unless references_eager_loaded_tables?

        # Rails 4.1 removes the `options` argument from AR::Relation#count
 #       args = [column_name]
        args = []
        args << options #if ActiveRecord::VERSION::STRING < '4.1.0'

        # .group returns an OrderdHash that responds to #count
        c = count(*args)
        if c.is_a?(Hash) || c.is_a?(ActiveSupport::OrderedHash)
          c.count
        else
          c.respond_to?(:count) ? c.count(*args) : c
        end
      end
    end
  end

  module PageScopeMethods
    # Specify the <tt>per_page</tt> value for the preceding <tt>page</tt> scope
    #   Model.page(3).per(10)
    def per(num)
      if (n = num.to_i) < 0 || !(/^\d/ =~ num.to_s)
        self
      elsif n.zero?
        limit(n)
      elsif Kaminari.config.max_per_page && Kaminari.config.max_per_page < n
        limit(Kaminari.config.max_per_page).offset(offset_value / limit_value * Kaminari.config.max_per_page)
      else
        limit(n).offset(offset_value / limit_value * n)
      end
    end

    # Total number of pages
    def total_pages
      count_without_padding = total_count
      count_without_padding -= @_padding if defined?(@_padding) && @_padding
      count_without_padding = 0 if count_without_padding < 0

      total_pages_count = (count_without_padding.to_f / limit_value).ceil
      if Kaminari.config.max_pages.present? && Kaminari.config.max_pages < total_pages_count
        Kaminari.config.max_pages
      else
        total_pages_count
      end
    rescue FloatDomainError
      raise ZeroPerPageOperation, "The number of total pages was incalculable. Perhaps you called .per(0)?"
    end
  end
end

ActiveFedora::Relation.class_eval do
  include Kaminari::ConfigurationMethods

  def page(num = nil)
    limit(Kaminari.config.default_per_page).offset(Kaminari.config.default_per_page * ((num = num.to_i - 1) < 0 ? 0 : num)).extending do
      include Kaminari::ActiveFedoraRelationMethods
      include Kaminari::PageScopeMethods
    end
  end

  delegate :to_json, to: :to_a
end
