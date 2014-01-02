module Permalink

  extend ActiveSupport::Concern

  included do
    belongs_to :permalink, property: :has_permalink

    attr_reader :permalink

    def permalink
      self.relationships(:has_permalink).first.to_s
    end
  end

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

  def create_or_update_permalink( object )
    updated = false
    if object.published? 
      permalink = permalink_for(object)

      if permalink
        current_permalink = object.relationships(:has_permalink)
        if ! current_permalink || current_permalink.empty? || current_permalink.try(:first) != permalink
          create_or_update_permalink!(object, permalink)
          updated = true
        end
      end
    end
    updated
  end

  def self.create_or_update_permalink!( object, permalink )
    object.remove_relationship(:has_permalink, nil)
    object.add_relationship(:has_permalink, permalink, true)
  end

end