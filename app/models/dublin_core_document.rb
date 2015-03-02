# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

class DublinCoreDocument < ActiveFedora::OmDatastream
  set_terminology do |t|
    t.root(:path=>"dc", :namespace_prefix=>"oai_dc", "xmlns:oai_dc"=>"http://www.openarchives.org/OAI/2.0/oai_dc/", "xmlns:dc"=>"http://purl.org/dc/elements/1.1/", :schema=>"http://www.openarchives.org/OAI/2.0/oai_dc.xsd")
    t.title(:namespace_prefix=>"dc")
    t.creator(:index_as=>[:not_searchable], :namespace_prefix=>"dc")
    t.subject(:namespace_prefix=>"dc")
    t.description(:namespace_prefix=>"dc")
    t.publisher(:index_as=>[:not_searchable], :namespace_prefix=>"dc")
    t.contributor(:namespace_prefix=>"dc")
    t.date(:namespace_prefix=>"dc")
    t.dc_type(:path=>"type", :namespace_prefix=>"dc")
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

    def prefix
      ""
    end

    def to_solr(solr_doc = {})
      solr_doc = super(solr_doc)
      solr_doc["dc_identifier_tesim"] = self.identifier
      return solr_doc
    end

end
