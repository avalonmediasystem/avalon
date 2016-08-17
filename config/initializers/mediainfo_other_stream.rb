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

# Monkey patch Mediainfo to get accuration durations
#Mediainfo.class_eval do
#  def mediainfo!
#    @last_command = "#{path} #{@escaped_full_filename} --Output=XML -f"    
#    run_command!
#  end 
#end
Mediainfo::AudioStream.class_eval do
  def accurate_duration
    duration = 0
    parsed_response[:audio]["duration"].split(':').reverse.each_with_index do |t, pow|
      t, milli = t.split('.') if pow == 0
      duration += milli.to_i if milli
      duration += t.to_i * (60 ** pow) * 1000 
    end
    duration
  end
end
