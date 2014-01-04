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
  

  def permalink
    val = self.relationships(:has_permalink).first
    val.nil? ? nil : val.value
  end

  def permalink=(value)
    self.remove_relationship(:has_permalink, nil)
    if value.present?
      self.add_relationship(:has_permalink, value, true)
    end
  end

  # wrap this method; do not use this method as a callback
  # if it returns false it will skip the rest of the items in the callback chain

  def ensure_permalink!
    updated = false

    begin
      permalink = self.permalink
      if permalink.blank?
        permalink = Permalink.permalink_for(self)
      end
    rescue Exception => e
      permalink = nil
      logger.error "Permalink.permalink_for() raised an exception for #{self.inspect}: #{e}"
    end
    
    if permalink.present? and not (self.permalink == permalink)
      self.permalink = permalink
      updated = true
    end
    
    updated
  end

end