require "net/https"
require "uri"

class AvalonCheck < OkComputer::Check
  def time_limit
    5
  end

  def status
    Timeout.timeout(time_limit) do
      ping
    end
  end

  def ping
    # to be overridden
  end

  def check
    begin
      mark_message "received #{status}"
    rescue StandardError => e
      mark_failure
      mark_message "error connecting"
      Rails.logger.warn e.full_message
    end
  end
end

class FedoraCheck < AvalonCheck
  def ping
    ActiveFedora.fedora.connection.http.get().status
  end
end

class SolrCheck < AvalonCheck
  def ping
    ActiveFedora.solr.conn.get('admin/ping')['status']
  end
end

class StreamingCheck < AvalonCheck
  def ping
    uri = URI.parse(Settings.streaming.http_base)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"

    request = Net::HTTP::Get.new("/")
    res = http.request(request)
    res.code
  end
end

OkComputer::Registry.register "fedora", FedoraCheck.new
OkComputer::Registry.register "solr", SolrCheck.new
OkComputer::Registry.register "streaming", StreamingCheck.new
OkComputer.check_in_parallel = true
OkComputer.mount_at = 'healthz'
