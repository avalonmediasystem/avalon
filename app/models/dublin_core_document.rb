class DublinCoreDocument < ActiveFedora::NokogiriDatastream
  set_terminology do |t|
    t.root(:path=>"dc", :namespace_prefix=>"oai_dc", "xmlns:oai_dc"=>"http://www.openarchives.org/OAI/2.0/oai_dc/", "xmlns:dc"=>"http://purl.org/dc/elements/1.1/", :schema=>"http://www.openarchives.org/OAI/2.0/oai_dc.xsd")
    t.title(:namespace_prefix=>"dc")
    t.creator(:index_as=>[:not_searchable], :namespace_prefix=>"dc")
    t.subject(:namespace_prefix=>"dc")
    t.description(:namespace_prefix=>"dc")
    t.publisher(:index_as=>[:not_searchable], :namespace_prefix=>"dc")
    t.contributor(:namespace_prefix=>"dc")
    t.date(:namespace_prefix=>"dc")
    t.dc_type(:namespace_prefix=>"dc")
    t.identifier(:namespace_prefix=>"dc")
    t.source(:namespace_prefix=>"dc")
    t.language(:namespace_prefix=>"dc")
    t.relation(:namespace_prefix=>"dc")
    t.coverage(:namespace_prefix=>"dc")
    t.rights(:namespace_prefix=>"dc")
    t.format(:namespace_prefix=>"dc")
    t.extent(:ref=>:format, :namespace_prefix=>"dc", :attributes => {:type=>"extent"})
    t.medium(:ref=>:format, :namespace_prefix=>"dc", :attributes => {:type=>"medium"})
  end
  
    # Generates an empty Video(used when you call Video.new without passing in existing xml)
    #  (overrides default behavior of creating a plain xml document)
    def self.xml_template
      # use Nokogiri to build the XML
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.dc("xmlns:oai_dc"=>"http://www.openarchives.org/OAI/2.0/oai_dc/",
           "xmlns:dc"=>"http://purl.org/dc/elements/1.1/",
           "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
           "xsi:schemaLocation"=>"http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd") {
	  xml.parent.namespace_definitions.each {|ns|
            xml.parent.namespace = ns if ns.prefix == 'oai_dc'
          }
        }
      end
      # return a Nokogiri::XML::Document, not an OM::XML::Document
      return builder.doc
    end

    def to_solr(solr_doc = {})
      super(solr_doc)
      solr_doc["dc_creator_t"] = self.creator
      solr_doc["dc_publisher_t"] = self.publisher
      return solr_doc
    end

end
