module Avalon
  module Permalink
    extend ActiveSupport::Concern
    
    @@generator = Proc.new { |obj| nil }
    def self.permalink_for(obj)
      @@generator.call(obj)
    end
      
    # Avalon::Permalink.on_generate do |obj|
    #   permalink = (... generate permalink ...)
    #   return permalink
    # end
    def self.on_generate(&block)
      @@generator = block
    end
  end
end