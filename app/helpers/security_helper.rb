module SecurityHelper
  def add_stream_cookies(stream_info)
    SecurityHandler.secure_cookies(target: stream_info[:id], request_host: request.server_name).each_pair do |name, value|
      cookies[name] = value
    end
  end

  def secure_streams(stream_info)
    add_stream_cookies(id: stream_info[:id])
    [:stream_flash, :stream_hls].each do |protocol|
      stream_info[protocol].each do |quality|
        quality[:url] = SecurityHandler.secure_url(quality[:url], session: session, target: stream_info[:id], protocol: protocol)
      end
    end
    stream_info
  end
end
