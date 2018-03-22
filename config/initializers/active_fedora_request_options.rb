class ActiveFedora::Fedora
  def request_options
    @config[:request]
  end

  def authorized_connection
    options = {}
    options[:request] = request_options if request_options
    connection = Faraday.new(host, options)
    connection.basic_auth(user, password)
    connection
  end
end

