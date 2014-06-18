# Monkey patch Mediainfo so it doesn't choke on stream type 'Other'

require 'mediainfo'
unless Mediainfo::SECTIONS.include? :other
  Mediainfo::SECTIONS << :other
  class Mediainfo::OtherStream < Mediainfo::Stream
    mediainfo_attr_reader :stream_id, "ID"
    mediainfo_attr_reader :type
  end
  
  class Mediainfo::Stream
    def other?; :other == @stream_type; end
  end
  
  class Mediainfo
    def other; @other_proxy ||= StreamProxy.new(self, :other); end
    def other?; streams.any? { |x| x.other? }; end
  end
end
