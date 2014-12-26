module Avalon
  class BibRetriever
    class Zoom < ::Avalon::BibRetriever
      
      def initialize config
        super
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
        record[0].nil? ? nil : marc2mods(record[0].raw)
      end
    end
  end
end
