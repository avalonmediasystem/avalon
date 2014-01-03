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
  

  included do
    def permalink
      self.relationships(:has_permalink).first.to_s
    end

    def permalink=(value)
      self.remove_relationship(:has_permalink, nil)
      self.add_relationship(:has_permalink, value, true)
    end

    # wrap this method; do not use this method as a callback
    # if it returns false it will skip the rest of the items in the callback chain

    def create_or_update_permalink( object )
      updated = false

      begin
        permalink = Permalink.permalink_for(object)
      rescue Exception => e
        permalink = nil
        logger.error "Permalink.permalink_for() raised an exception for #{object.inspect}: #{e}"
      end
      
      if permalink
        current_permalink = object.relationships(:has_permalink)
        if ! current_permalink || current_permalink.empty? || current_permalink.try(:first) != permalink
          object.permalink = permalink
          updated = true
        end
      end
      
      updated
    end
  end

end