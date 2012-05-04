class VideoPbcoreDatastream < ActiveFedora::NokogiriDatastream
  set_terminology do |t|
    t.root(:path => "pbcoreDescriptionDocument", 
      :xmlns =>"http://www.pbcore.org/PBCore/PBCoreNamespace.html",
      :schema => "http://www.pbcore.org/PBCore/PBCoreNamespace.html http://www.pbcore.org/PBCore/PBCoreSchema.xsd")
    #
    t.pbcore_identifier {
      t.identifier(:path => 'identifier', :index_as => [:facetable])
      t.identifier_source(:path => 'identifierSource')
    }
    
    t.pbcore_title {
      t.title(:path => 'title', :index_as => [:facetable], :label => 'title')
      t.title_type(:path => 'titleType')
    }
    t.pbcore_subject {
      t.subject(:path => 'subject', :index_as => [:facetable], :label => 'subject',
        :repeatable => true)
    }
    
    t.pbcore_description {
      t.description(:path => 'description')
    }
    
    t.pbcore_coverage {
      t.coverage(:path => 'coverage')
    }
    t.spatial(:ref => :pbcore_coverage, :path => 'pbcoreCoverage[coverageType="spatial"]')
    t.temporal(:ref => :pbcore_coverage, :path => 'pbcoreCoverage[coverageType="temporal"]')
    
    t.pbcore_creator {
      t.creator(:path => 'creator', :index_as => [:facetable], :label => 'Creator')
    }
    t.author(:ref => [:pbcore_creator, :creator])
    
    # Proxies for frequently used nested fields
    t.subject(:ref => [:pbcore_subject, :subject])
    t.abstract(:ref => [:pbcore_description, :description])
  end

    # Generates an empty Video(used when you call Video.new without passing in existing xml)
    #  (overrides default behavior of creating a plain xml document)
    def self.xml_template
      # use Nokogiri to build the XML
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.pbcoreDocument(
           "xmlns:xsi"=> "http://www.w3.org/2001/XMLSchema-instance",
           "xmlns"=> "http://www.pbcore.org/PBCore/PBCoreNamespace.html",
           "xsi:schemaLocation"=> "http://www.pbcore.org/PBCore/PBCoreNamespace.html http://www.pbcore.org/PBCore/PBCoreSchema.xsd") {
          xml.pbcoreTitle {
            xml.title
            xml.titleType('mainTitle')
          }
          xml.pbcoreSubject {
            xml.subject
          }
          xml.pbcoreDescription {
            xml.description('This is a stub.')
          }
          xml.pbcoreCoverage {
            xml.coverage('Bloomington (Ind)')
            xml.coverageType('spatial')
          }
          xml.pbcore_creator {
             xml.creator
          }
        }
      end
      # return a Nokogiri::XML::Document, not an OM::XML::Document
      return builder.doc
    end
end
