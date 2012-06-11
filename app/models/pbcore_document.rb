class PbcoreDocument < ActiveFedora::NokogiriDatastream
  
  # First iteration includes a bare bones PBCore record with just identifier, title,
  # and other required fields
  set_terminology do |t|
    t.root(path: "pbcoreDescriptionDocument", xmlns: '', namespace_prefix: nil)
    
    # Required fields
    t.primary_id(path: "pbcoreIdentifier", xmlns: '', namespace_prefix: nil)
    t.title(path: "pbcoreTitle", xmlns: '', namespace_prefix: nil)
    t.abstract(path: "pbcoreDescription", xmlns: '', namespace_prefix: nil)
    
    # Other fields required by the data dictionary
    t.created_on(path: "pbcoreAssetDate", attributes: {dateType: 'created'}, 
      xmlns: '', namespace_prefix: nil)
    
    # Contributors, creators, and publishers
    t.creator(path: "pbcoreCreator/creator", xmlns: '', namespace_prefix: nil)
    t.pbcore_contributor(path: "pbcoreContributor") {
      t.contributor(path: "contributor")
      t.contributor_role(path: "contributorRole")
    }
    
    # Coverage information
    t.pbcore_coverage(path: "pbcoreCoverage") {
      t.coverage(path: "coverage")
    }
    t.spatial(ref: :pbcore_coverage, 
      path: "pbcoreCoverage[coverageType='spatial']",
      namespace_prefix: nil)
    t.temporal(ref: :pbcore_coverage, 
      path: "pbcoreCoverage[coverageType='temporal']",
      namespace_prefix: nil)
  end
  
  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.pbcoreDescriptionDocument("xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xsi:schemaLocation" => "http://www.pbcore.org/PBCore/PBCoreNamespace.html") {
        xml.pbcoreAssetDate(Time.now, dateType: "created")
        xml.pbcoreIdentifier(annotation: "pid")
        xml.pbcoreTitle(titleType: "main")
        xml.pbcoreDescription
        xml.pbcoreCreator {
          xml.creator
        }
      }
    end
    return builder.doc
  end
end