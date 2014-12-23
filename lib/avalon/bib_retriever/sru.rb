module Avalon
  class BibRetriever
    class SRU
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def get_record(bib_id)
        uri = URI.parse config['url']
        uri.query = "version=1.1&operation=searchRetrieve&maximumRecords=10000&recordSchema=mods&query=rec.id=#{bib_id}"
        doc = Nokogiri::XML RestClient.get(uri.to_s)
        record = doc.xpath('//zs:recordData/*', "zs"=>"http://www.loc.gov/zing/srw/").first
        record.nil? ? nil : record.to_s
      end
    end
  end
end
