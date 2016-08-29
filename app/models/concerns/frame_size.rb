module FrameSize
  extend ActiveSupport::Concern
  
  module ClassMethods
    def frame_size_property(property_name, *args, &block)
      property :width, predicate: ::RDF::Vocab::EBUCore.width, multiple: false, &block
      property :height, predicate: ::RDF::Vocab::EBUCore.height, multiple: false, &block
      property property_name, *args, &block

      alias_method :_width=, :width=
      define_method :width= do |value|
        setting_frame_size do
          { width: value, property_name => [value,height].compact.join('x') }
        end
      end
      
      alias_method :_height=, :height=
      define_method :height= do |value|
        setting_frame_size do
          { height: value, property_name => [width,value].compact.join('x') }
        end
      end

      alias_method "_#{property_name}=".to_sym, "#{property_name}=".to_sym
      define_method "#{property_name}=".to_sym do |value|
        (w,h) = value.to_s.split('x')
        w = w.to_i unless w.nil?
        h = h.to_i unless h.nil?
        setting_frame_size do
          { width: w, height: h, property_name => value }
        end
      end
    end
  end

  private
  def setting_frame_size
    setters = yield
    setters.each_pair do |property, value|
      self.send("_#{property}=".to_sym,value)
    end
  end
end
