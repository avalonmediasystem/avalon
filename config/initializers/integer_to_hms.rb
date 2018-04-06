int_class = if RUBY_VERSION < "2.4"
              Fixnum # rubocop:disable Lint/UnifiedInteger
            else
              Integer
            end

int_class.class_eval do
  def to_hms
    h = 1.hour * 1000
    m = 1.minute * 1000
    s = 1000.0

    v = self
    hour = v / h
    v -= hour * h
    min = v / m
    v -= min * m
    sec = v / s
    format('%2.2d:%2.2d:%06.3f', hour, min, sec)
  end
end
