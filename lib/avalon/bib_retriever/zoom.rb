module Avalon
  class BibRetriever
    class Zoom
      XSLT_FILE = File.expand_path('../MARC21slim2MODS3-5.xsl',__FILE__)
      
      attr_reader :config
      
      def initialize(config)
        @config = config
        @config['port'] ||= 7090
        @config['attribute'] ||= 7
      end
      
      def get_record(bib_id)
        record = nil
        ZOOM::Connection.open(config['host'], config['port']) do |conn|
          conn.database_name = config['database']
          conn.preferred_record_syntax = 'marc21'
          record = conn.search("@attr 1=#{config['attribute']} #{bib_id}")
        end
        if record[0].nil?
          return nil
        else
          return marc2mods(record[0].raw)
        end
      end
      
      def marc2mods(marc)
        marc = MARC::Reader.decode marc
        marcxml = marc.to_xml.to_s
        doc = Nokogiri::XML(marcxml)
        
        xsl = Nokogiri::XSLT.parse(File.read(XSLT_FILE))
        mods = xsl.transform(doc)
        mods.to_s
      end
    end
  end
end
