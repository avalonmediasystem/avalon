module Avalon
  class BibRetriever
    extend Forwardable
    def_delegator :@driver, :get_record
    
    def initialize
      config = Avalon::Configuration.lookup('bib_retriever')
      case config['protocol'].downcase
      when 'sru', /^yaz/
        require 'avalon/bib_retriever/sru'
        @driver = Avalon::BibRetriever::SRU.new config
      when /^z(oom|39)/
        require 'avalon/bib_retriever/zoom'
        @driver = Avalon::BibRetriever::Zoom.new config
      else
        raise ArgumentError, "Unknown bib retriever protocol: #{config['protocol']}"
      end
    end
  end
end
