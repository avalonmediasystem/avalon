module SecurityHelper
  def secure_streams(stream_info)
    [:stream_flash, :stream_hls].each do |protocol|
      stream_info[protocol].each do |quality|
        quality[:url] = SecurityHandler.secure_url(quality[:url], session: session, target: stream_info[:id])
      end
    end
    stream_info
  end
end
