class Pbcore
  def self.insert_pbcore_namespace(document)
    index = doc.to_s.index("xmlns:xsi")
     new_document = doc.to_s.insert(index.to_i, 'xmlns="http://www.pbcore.org/PBCoreNamespace.html" ')
    new_doc = Nokogiri::XML(new_document
  end
  
  def self.validate
     # What goes here?
   end

   # For now the fields audienceLevel and audienceRating do not seem to be of much
   # use so they have been left out pending the finalization of the project's
   # data dictionary
   def self.reorder_document
     nodes = ["pbcoreAssetType", "pbcoreAssetDate", "pbcoreIdentifier",
       "pbcoreTitle", "pbcoreSubject", "pbcoreDescription", "pbcoreGenre",
       "pbcoreRelation", "pbcoreCoverage", "pbcoreCreator", "pbcoreContributor",
       "pbcorePublisher", "pbcoreRightsSummary", "pbcoreInstantiation",
       "pbcoreAnnotation", "pbcoreExtension"]
   end
end