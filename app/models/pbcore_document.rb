# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

class PbcoreDocument < ActiveFedora::NokogiriDatastream
  include PbcoreMethods
  
  # Define the proper order of the elements so that once you are ready to save you can
  # reorder them to create a semantically valid XML document that validates against the
  # PBCore 2.0 schema. Use the element name as it appears in the document rather than
  # the alias created in the terminology
  #
  # The reorganization is done by invoking the reorder_elements within an object that
  # contains this datastream
  #
  # IE : Within a media_object
  #     
  #      before_save descMetadata.reorder_elements
  ELEMENT_ORDER = [
    "pbcoreAssetType",
    "pbcoreAssetDate",
    "pbcoreIdentifier",
    "pbcoreTitle",
    "pbcoreSubject",
    "pbcoreDescription",
    "pbcoreGenre",
    "pbcoreRelation",
    "pbcoreCoverage",
    "pbcoreAnnotation",
    "pbcoreCreator",
    "pbcoreContributor",
    "pbcorePublisher",
    "pbcoreRightsSummary",
    "pbcoreInstantiation",
    "pbcoreExtension",
    "pbcorePart"
  ]
  
  set_terminology do |t|
    t.root(:path=>"pbcoreDescriptionDocument", 
      :xmlns => 'http://www.pbcore.org/PBCore/PBCoreNamespace.html', 
      :namespace_prefix=>nil,
      :schema => 'http://pbcore.org/xsd/pbcore-2.0.xsd')

    #
    #  pbcoreDescription fields
    #
    t.asset_date(:path => "pbcoreAssetDate", :namespace_prefix => nil)
    t.creation_date(:path => 'pbcoreAssetDate', 
      :attributes => { :dateType => 'created' },
      :namespace_prefix => nil )

    t.asset_type(:path => "pbcoreAssetType", :namespace_prefix => nil)
    t.identifier(:path=>"pbcoreIdentifier", :namespace_prefix => nil)
    
    # Various types of titles
    t.main_title(:path=>"pbcoreTitle", :namespace_prefix=>nil, :attributes=>{ :titleType=>"main" })
    t.alternative_title(:path=>"pbcoreTitle", :namespace_prefix=>nil, :attributes=>{ :titleType=>"alternative" })
    t.chapter(:path=>"pbcoreTitle", :namespace_prefix=>nil, :attributes=>{ :titleType=>"Chapter" })
    t.episode(:path=>"pbcoreTitle", :namespace_prefix=>nil, :attributes=>{ :titleType=>"Episode" })
    t.label(:path=>"pbcoreTitle", :namespace_prefix=>nil, :attributes=>{ :titleType=>"Label" })
    t.segment(:path=>"pbcoreTitle", :namespace_prefix=>nil, :attributes=>{ :titleType=>"Segment" })
    t.subtitle(:path=>"pbcoreTitle", :namespace_prefix=>nil, :attributes=>{ :titleType=>"Subtitle" })
    t.track(:path=>"pbcoreTitle", :namespace_prefix=>nil, :attributes=>{ :titleType=>"Track" })
    t.translation(:path=>"pbcoreTitle", :namespace_prefix=>nil, :attributes=>{ :titleType=>"Translation" })

    # This is only to display all subjects
    t.subjects(:path=>"pbcoreSubject", :namespace_prefix=>nil)

    # Individual subject types defined for entry
    t.lc_subject(:path=>"pbcoreSubject", :namespace_prefix=>nil, :attributes=>{ :source=>"lcsh", :ref=>"http://id.loc.gov/authorities/subjects.html" })
    t.lc_name(:path=>"pbcoreSubject", :namespace_prefix=>nil, :attributes=>{ :source=>"Library of Congress Name Authority File", :ref=>"http://id.loc.gov/authorities/names" })

    t.summary(:path=>"pbcoreDescription", :namespace_prefix=>nil, :attributes=>{ :descriptionType=>"Description",
      :descriptionTypeSource=>"pbcoreDescription/descriptionType",
      :descriptionTypeRef=>"http://pbcore.org/vocabularies/pbcoreDescription/descriptionType#description",
      :annotation=>"Summary"}
    )

    t.parts_list(:path=>"pbcoreDescription", :namespace_prefix=>nil, :attributes=>{ :descriptionType=>"Table of Contents",
      :descriptionTypeSource=>"pbcoreDescription/descriptionType",
      :descriptionTypeRef=>"http://pbcore.org/vocabularies/pbcoreDescription/descriptionType#table-of-contents",
      :annotation=>"Parts List" }
    )

    # This is only to display all genres
    t.genres(:path=>"pbcoreGenre", :namespace_prefix=>nil)

    # Individual genre types defined for entry
    t.genre(:path=>"pbcoreGenre", :namespace_prefix=>nil)

    t.getty_genre(:path=>"pbcoreGenre", :namespace_prefix=>nil, :attributes=>{ :source=>"getty", :ref=>"http://www.getty.edu/research/tools/vocabularies/aat/index.html" })
    t.lc_genre(:path=>"pbcoreGenre", :namespace_prefix=>nil, :attributes=>{ :source=>"Library of Congress Genre/Form Terms", :ref=>"http://id.loc.gov/authorities/genreForms.html" })
    t.lc_subject_genre(:path=>"pbcoreGenre", :namespace_prefix=>nil, :attributes=>{ :source=>"lcsh", :ref=>"http://id.loc.gov/authorities/subjects.html" })

    # Series field
    t.relation(:path=>"pbcoreRelation", :namespace_prefix=>nil) {
      t.pbcoreRelationType(:namespace_prefix=>nil)
      t.pbcoreRelationIdentifier(:namespace_prefix=>nil)
    }
    t.relation_type(:proxy=>[:relation, :pbcoreRelationType])
    t.relation_identifier(:proxy=>[:relation, :pbcoreRelationIdentifier])

    # Terms for time and place
    t.pbcore_coverage(:path=>"pbcoreCoverage", :namespace_prefix=>nil) {
      t.coverage_(:path=>"coverage", :namespace_prefix=>nil)
      t.coverage_type(:path => "coverageType", :namespace_prefix => nil)
    }
    t.temporal(:ref => :pbcore_coverage, :path => "pbcoreCoverage[./coverageType='Temporal']")
    t.spatial(:ref => :pbcore_coverage, :path => "pbcoreCoverage[./coverageType='Spatial']")
    # Display all coverage values regardless of type
    t.coverages(:ref => :pbcore_coverage, :path => "pbcoreCoverage")
    
    t.spatial_coverage(:proxy => [:spatial, :coverage])
    t.spatial_role(:proxy => [:spatial, :coverage_type])
    t.temporal_coverage(:proxy => [:temporal, :coverage])
    t.temporal_role(:proxy => [:temporal, :coverage_type])

    # Contributor names and roles
    t.creator(:path=>"pbcoreCreator", :namespace_prefix=>nil) {
      t.name_(:path=>"creator", :namespace_prefix=>nil)
      t.role_(:path=>"creatorRole", :namespace_prefix=>nil, 
        :attributes=>{ :source=>"MARC relator terms" })
    }
    t.creator_name(:proxy=>[:creator, :name])
    t.creator_role(:proxy=>[:creator, :role])

    # Contributor names and roles
    t.contributor(:path=>"pbcoreContributor", :namespace_prefix=>nil) {
      t.name_(:path=>"contributor", :namespace_prefix=>nil)
      t.role_(:path=>"contributorRole", :namespace_prefix=>nil, 
        :attributes=>{ :source=>"MARC relator terms" })
    }
    t.contributor_name(:proxy=>[:contributor, :name])
    t.contributor_role(:proxy=>[:contributor, :role])

    # Publisher names and roles
    t.publisher(:path=>"pbcorePublisher", :namespace_prefix=>nil) {
      t.name_(:path=>"publisher", :namespace_prefix=>nil)
      t.role_(:path=>"publisherRole", :namespace_prefix=>nil, :attributes=>{ :source=>"PBCore publisherRole" })
    }
    t.publisher_name(:proxy=>[:publisher, :name])
    t.publisher_role(:proxy=>[:publisher, :role])

    t.note(:path=>"pbcoreAnnotation", :namespace_prefix=>nil, :atttributes=>{ :annotationType=>"Notes" })

    #
    # pbcoreInstantiation fields for the physical item
    #
    t.pbcoreInstantiation(:namespace_prefix=>nil) {
      t.instantiationIdentifier(:namespace_prefix=>nil, :attributes=>{})
      t.instantiationDate(:namespace_prefix=>nil, :attributes=>{ :dateType=>"created" })
      t.instantiationPhysical(:namespace_prefix=>nil, :attributes=>{ :source=>"PBCore instantiationPhysical" })
      t.instantiationStandard(:namespace_prefix=>nil)
      t.instantiationLocation(:namespace_prefix=>nil)
      t.instantiationMediaType(:namespace_prefix=>nil, :attributes=>{ :source=>"PBCore instantiationMediaType" })
      t.instantiationGenerations(:namespace_prefix=>nil, :attributes=>{ :source=>"PBCore instantiationGenerations" })
      t.instantiationColors(:namespace_prefix=>nil)
      t.instantiationLanguage(:namespace_prefix=>nil, :attributes=>{ :source=>"ISO 639.2", :ref=>"http://www.loc.gov/standards/iso639-2/php/code_list.php" })
      t.instantiationRelation(:namespace_prefix=>nil) {
        t.arc_collection(:path=>"instantiationRelationIdentifier", :namespace_prefix=>nil, :attributes=>{ :annotation=>"Archival collection" })
        t.arc_series(:path=>"instantiationRelationIdentifier", :namespace_prefix=>nil, :attributes=>{ :annotation=>"Archival Series" })
        t.col_number(:path=>"instantiationRelationIdentifier", :namespace_prefix=>nil, :attributes=>{ :annotation=>"Collection Number" })
        t.acc_number(:path=>"instantiationRelationIdentifier", :namespace_prefix=>nil, :attributes=>{ :annotation=>"Accession Number" })
      }
      t.instantiationRights(:namespace_prefix=>nil) {
        t.rightsSummary(:namespace_prefix=>nil)
      }
      t.inst_cond_note(:path=>"instantiationAnnotation", :namespace_prefix=>nil, :attributes=>{ :annotationType=>"Condition Notes" })
      t.inst_clean_note(:path=>"instantiationAnnotation", :namespace_prefix=>nil, :attributes=>{ :annotationType=>"Cleaning Notes" })
    }
    # Individual field names:
    t.instantiation_date(:proxy=>[:pbcoreInstantiation, :instantiationDate])
    t.barcode(:proxy=>[:pbcoreInstantiation, :instantiationIdentifier])
    t.repository(:proxy=>[:pbcoreInstantiation, :instantiationLocation])
    t.format(:proxy=>[:pbcoreInstantiation, :instantiationPhysical])
    t.standard(:proxy=>[:pbcoreInstantiation, :instantiationStandard])
    t.media_type(:proxy=>[:pbcoreInstantiation, :instantiationMediaType])
    t.generation(:proxy=>[:pbcoreInstantiation, :instantiationGenerations])
    t.language(:proxy=>[:pbcoreInstantiation, :instantiationLanguage])
    t.colors(:proxy=>[:pbcoreInstantiation, :instantiationColors])
    t.archival_collection(:proxy=>[:pbcoreInstantiation, :instantiationRelation, :arc_collection])
    t.archival_series(:proxy=>[:pbcoreInstantiation, :instantiationRelation, :arc_series])
    t.collection_number(:proxy=>[:pbcoreInstantiation, :instantiationRelation, :col_number])
    t.accession_number(:proxy=>[:pbcoreInstantiation, :instantiationRelation, :acc_number])
    t.usage(:proxy=>[:pbcoreInstantiation, :instantiationRights, :rightsSummary])
    t.condition_note(:proxy=>[:pbcoreInstantiation, :inst_cond_note])
    t.cleaning_note(:proxy=>[:pbcoreInstantiation, :inst_clean_note])

    #
    # pbcorePart fields
    #
    t.pbcorePart(:namespace_prefix=>nil) {
      t.pbcoreTitle(:namespace_prefix=>nil, :attributes=>{ :annotation=>"part title" })
      t.pbcoreIdentifier(:namespace_prefix=>nil, :attributes=>{ :annotation=>"part number" })
      t.pbcoreDescription(:namespace_prefix=>nil, :attributes=>{ :descriptionType=>"Description",
        :descriptionTypesource=>"pbcoreDescription/descriptionType",
        :ref=>"http://pbcore.org/vocabularies/pbcoreDescription/descriptionType#description" }
      )
      t.pbcoreContributor(:namespace_prefix=>nil) {
        t.contributor(:attributes=>{ :annotation=>"part contributor" })
        t.contributorRole(:attributes=>{ :source=>"MARC relator terms" })
      }
    }
    t.part_title(:ref=>[:pbcorePart, :pbcoreTitle])
    t.part_number(:ref=>[:pbcorePart, :pbcoreIdentifier])
    t.part_description(:ref=>[:pbcorePart, :pbcoreDescription])
    t.part_contributor(:ref=>[:pbcorePart, :pbcoreContributor, :contributor])
    t.part_role(:ref=>[:pbcorePart, :pbcoreContributor, :contributorRole])
  end

  define_template :contributor do |xml, name, role="contributor"|
    xml.pbcoreContributor {
      xml.contributor { xml.text name }
      xml.contributorRole { xml.text role }
    }
  end

  define_template :publisher do |xml, name, role="contributor"|
    xml.pbcorePublisher {
      xml.publisher { xml.text name }
      xml.publisherRole { xml.text role }
    }
  end

  define_template :pbcore_coverage do |xml, value, type=nil|
    xml.pbcoreCoverage {
      xml.coverage { xml.text value }
      xml.coverageType { xml.text type } unless type.blank?
    }
  end

  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
    xml.pbcoreDescriptionDocument("xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation"=>"http://www.pbcore.org/PBCore/PBCoreNamespace.html http://pbcore.org/xsd/pbcore-2.0.xsd") {

        xml.pbcoreIdentifier(:source=>"Avalon Media System", :annotation=>"pid")
        xml.pbcoreTitle(:titleType=>"uniform")
        xml.pbcoreDescription(:annotation=>"summary")
    }
    end
    return builder.doc
  end

  def self.blank_template
    builder = Nokogiri::XML::Builder.new do |xml|
    xml.pbcoreDescriptionDocument(
      "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
      "xsi:schemaLocation"=>"http://www.pbcore.org/PBCore/PBCoreNamespace.html http://pbcore.org/xsd/pbcore-2.0.xsd") {
        }
    end
    return builder.doc
  end

  def to_solr(solr_doc=SolrDocument.new)
    super(solr_doc)

    solr_doc.merge!(:title_t => self.find_by_terms(:main_title).text)

    # Specific fields for Blacklight export

    # Title fields
    solr_doc.merge!(:title_display => self.find_by_terms(:main_title).text)
    ["alternative_title", "chapter", "episode", "label", "segment", "subtitle", "track", "translation"].each do |addl_title|
      solr_doc.merge!(:title_addl_display => self.find_by_terms(addl_title.to_sym).text)
    end
    solr_doc.merge!(:heading_display => self.find_by_terms(:main_title).text)

    # Individual fields
    solr_doc.merge!(:summary_display => self.find_by_terms(:summary).text)
    solr_doc.merge!(:publisher_display => gather_terms(self.find_by_terms(:publisher_name)))
    solr_doc.merge!(:contributors_display => gather_terms(self.find_by_terms(:contributor_name)))
    solr_doc.merge!(:subject_display => gather_terms(self.find_by_terms(:subjects)))
    solr_doc.merge!(:genre_display => gather_terms(self.find_by_terms(:genres)))
#    solr_doc.merge!(:physical_dtl_display => gather_terms(self.find_by_terms(:format)))
    solr_doc.merge!(:contents_display => gather_terms(self.find_by_terms(:parts_list)))
    solr_doc.merge!(:notes_display => gather_terms(self.find_by_terms(:note)))
    solr_doc.merge!(:access_display => gather_terms(self.find_by_terms(:usage)))
    solr_doc.merge!(:collection_display => gather_terms(self.find_by_terms(:archival_collection)))
    solr_doc.merge!(:format_display => gather_terms(self.find_by_terms(:media_type)))

    # Blacklight facets - these are the same facet fields used in our Blacklight app
    # for consistency and so they'll show up when we export records from Hydra into BL:
    solr_doc.merge!(:material_facet => "Digital")
    solr_doc.merge!(:genre_facet => gather_terms(self.find_by_terms(:genres)))
    solr_doc.merge!(:contributor_facet => gather_terms(self.find_by_terms(:contributor_name)))
    solr_doc.merge!(:publisher_facet => gather_terms(self.find_by_terms(:publisher_name)))
    solr_doc.merge!(:subject_topic_facet => gather_terms(self.find_by_terms(:subjects)))
    solr_doc.merge!(:format_facet => gather_terms(self.find_by_terms(:media_type)))
    solr_doc.merge!(:location_facet => gather_terms(self.find_by_terms(:spatial_coverage)))
#    solr_doc.merge!(:time_facet => gather_terms(self.find_by_terms(:temporal)))

    # TODO: map PBcore's three-letter language codes to full language names
    # Right now, everything's English.
    if self.find_by_terms(:language).text.match("eng")
      solr_doc.merge!(:language_facet => "English")
      solr_doc.merge!(:language_display => "English")
    else
      solr_doc.merge!(:language_facet => "Unknown")
      solr_doc.merge!(:language_display => "Unknown")
    end

    # Extract 4-digit year for creation date facet in Hydra and pub_date facet in Blacklight
		create = self.find_by_terms(:creation_date).text.strip
		unless create.nil? or create.empty?
		  solr_doc.merge!(:create_date_facet => get_year(create))
		  solr_doc.merge!(:pub_date => get_year(create))
		end

		# For full text, we stuff it into the mods_t field which is already configured for Mods doucments
		solr_doc.merge!(:mods_t => self.ng_xml.text)

    return solr_doc
  end

  # Method based on example from Rock and Roll Hall of Fame's PBCore implementation at
  # https://github.com/awead/Hydra-Rock/blob/master/lib/rockhall/pbcore.rb
  def reorder_elements
    logger.debug "<< REORDER ELEMENTS >>"
    
    new_doc = self.class.blank_template
    
    logger.debug "<< {BEFORE} >>"
    logger.debug "<< #{new_doc.to_xml} >>"
    logger.debug "<< #{self.to_xml} >>"

    ELEMENT_ORDER.each do |node|
      self.ng_xml.search(node).each do |element|
        logger.debug "<< Element is a #{element.class} >>"
        logger.debug "<< Inserting #{element} into document >>"
        new_doc.root.add_child(element.clone)        
      end
    end
    
    logger.debug "<< {AFTER} >>"
    logger.debug "<< #{new_doc.class} >>"
    logger.debug "<< #{ng_xml.class} >>"
    self.ng_xml = new_doc
  end
  
  private

  def gather_terms(terms)
    results = Array.new
    terms.each { |r| results << r.text }
    return results.compact.uniq
  end

  def get_year(s)
    begin
      DateTime.parse(s).year.to_s
    rescue
      if s.match(/^\d{4}$/)
        return s.to_s
      elsif s.match(/^(\d{4})-\d{2}$/)
        return $1.to_s
      else
        return nil
      end
    end
  end
end
