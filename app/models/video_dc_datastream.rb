class VideoDCDatastream < ActiveFedora::NokogiriDatastream
  set_terminology do |t|
    t.root(:path=>"dc", :xmlns=>"http://purl.org/dc/elements/1.1/", :schema=>"http://dublincore.org/schemas/xmls/simpledc20021212.xsd")
    t.title(:index_as=>[:facetable])
    t.creator(:index_as=>[:facetable])
    t.subject(:index_as=>[:facetable])
    t.description
    t.publisher
    t.contributor
    t.date
    t._type
    t.identifier
    t.source
    t.language
    t.relation
    t.coverage
    t.rights
  end

    # Generates an empty Video(used when you call Video.new without passing in existing xml)
    #  (overrides default behavior of creating a plain xml document)
    def self.xml_template
      # use Nokogiri to build the XML
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.dc(:version=>"1.1",
           "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
           "xmlns"=>"http://purl.org/dc/elements/1.1/",
           "xsi:schemaLocation"=>"http://dublincore.org/schemas/xmls/simpledc20021212.xsd") {
          xml.title
          xml.creator
	  			xml.subject
          xml.description
          xml.date
					xml.source
        }
      end
      # return a Nokogiri::XML::Document, not an OM::XML::Document
      return builder.doc
    end
end
