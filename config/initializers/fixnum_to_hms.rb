class Fixnum
  def to_hms
    h = 1.hour * 1000
    m = 1.minute * 1000
    s = 1000.0

    v = self
    hour = v/h ; v -= hour*h
    min  = v/m ; v -= min*m
    sec  = v/s
    '%2.2d:%2.2d:%06.3f' % [hour,min,sec]
  end
end
