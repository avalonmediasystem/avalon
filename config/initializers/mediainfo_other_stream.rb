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

# def mediainfo_duration_reader(*a)
#   mediainfo_attr_reader *a do |v|
#     t = 0
#     v.scan(/\d+\s*\w+/).each do |tf|
#       case tf.gsub(/\s*/,'')
#       # XXX haven't actually seen hot they represent hours yet
#       # but hopefully this is ok.. :\
#       when /\d+h/  then t += tf.to_i * 60 * 60 * 1000
#       when /\d+mn/ then t += tf.to_i * 60 * 1000
#       when /\d+min/ then t += tf.to_i * 60 * 1000
#       when /\d+ms/ then t += tf.to_i
#       when /\d+s/  then t += tf.to_i * 1000
#       else
# byebug
#         raise "unexpected time fragment! please report bug!"
#       end
#     end
#     t
#   end
# end
