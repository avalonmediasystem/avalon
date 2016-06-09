require 'addressable/uri'

class URI::Parser
  def split url
    begin
      a = Addressable::URI::parse url
      [a.scheme, a.userinfo, a.host, a.port, nil, a.path, nil, a.query, a.fragment]
    rescue Addressable::URI::InvalidURIError => err
      raise URI::InvalidURIError, err.message
    end
  end
end
