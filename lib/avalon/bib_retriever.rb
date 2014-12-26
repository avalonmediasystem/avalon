module Avalon
  class BibRetriever
    XSLT_FILE = File.expand_path('../bib_retriever/MARC21slim2MODS3-5-avalon.xsl',__FILE__)
    attr_reader :config
    
    class << self
      def instance
        if @instance.nil?
          config = Avalon::Configuration.lookup('bib_retriever')
          case config['protocol'].downcase
          when 'sru', /^yaz/
            require 'avalon/bib_retriever/sru'
            @instance = Avalon::BibRetriever::SRU.new config
          when /^z(oom|39)/
            require 'avalon/bib_retriever/zoom'
            @instance = Avalon::BibRetriever::Zoom.new config
          else
            raise ArgumentError, "Unknown bib retriever protocol: #{config['protocol']}"
          end
        end
        @instance
      end
      
      protected :new, :allocate
    end
    
    def initialize config
      @config = config
    end

    def marcxml2mods(marcxml)
      doc = Nokogiri::XML(marcxml)
      xsl = Nokogiri::XSLT.parse(File.read(XSLT_FILE))
      mods = xsl.transform(doc)
      mods.to_s
    end
    
    def marc2mods(marc)
      record = MARC::Reader.decode marc
      marcxml = record.to_xml.to_s
      marcxml2mods(marcxml)
    end
  end
end
