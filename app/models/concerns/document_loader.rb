module DocumentLoader
  class << self
    def local_document_loader(url, options = {}, &block)
      if RDF::URI(url) == RDF::URI(RDFAnnotation::CONTEXT_URI)
        remote_document = JSON::LD::API::RemoteDocument.new(File.read(Rails.root.join('lib', 'active_annotations', 'oa.jsonld')), base: url)
        block_given? ? yield(remote_document) : remote_document
      else
        # :nocov:
        JSON::LD::API.documentLoader(url, options, &block)
        # :nocov:
      end
    end

    def document_loader
      ENV['NO_RDF_CACHE'] == '1' ? JSON::LD::API.method(:documentLoader) : self.method(:local_document_loader)
    end
  end
end
