module Avalon
  class BibRetriever
    class SRU < ::Avalon::BibRetriever
      def get_record(bib_id)
        uri = URI.parse config['url']
        uri.query = "version=1.1&operation=searchRetrieve&maximumRecords=10000&recordSchema=marcxml&query=rec.id=#{bib_id}"
        doc = Nokogiri::XML RestClient.get(uri.to_s)
        record = doc.xpath('//zs:recordData/*', "zs"=>"http://www.loc.gov/zing/srw/").first
        record.nil? ? nil : marcxml2mods(record.to_s)
      end
    end
  end
end
