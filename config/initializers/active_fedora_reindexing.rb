ActiveFedora::Fedora.class_eval do
    def header_options
      @config[:headers]
    end

    def authorized_connection
      options = {}
      options[:ssl] = ssl_options if ssl_options
      options[:request] = request_options if request_options
      options[:headers] = header_options if header_options
      Faraday.new(host, options) do |conn|
        conn.response :encoding # use Faraday::Encoding middleware
        conn.adapter Faraday.default_adapter # net/http
        if Gem::Version.new(Faraday::VERSION) < Gem::Version.new('2')
          conn.request :basic_auth, user, password
        else
          conn.request :authorization, :basic, user, password
        end
      end
    end

    def ntriples_connection
      authorized_connection.tap { |conn| conn.headers['Accept'] = 'application/n-triples' }
    end

    def build_ntriples_connection
      ActiveFedora::InitializingConnection.new(ActiveFedora::CachingConnection.new(ntriples_connection, omit_ldpr_interaction_model: true), root_resource_path)
    end
end

ActiveFedora::Indexing::DescendantFetcher.class_eval do
  private
    def rdf_resource
      @rdf_resource ||= Ldp::Resource::RdfSource.new(ActiveFedora.fedora.build_ntriples_connection, uri)
    end
end
