# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

# require 'avalon/bib_retriever'

class ModsDocument < ActiveFedora::OmDatastream

  include ModsTemplates
  include ModsBehaviors

  IDENTIFIER_TYPES = Avalon::ControlledVocabulary.find_by_name(:identifier_types) || {"other" => "Local"}
  NOTE_TYPES = Avalon::ControlledVocabulary.find_by_name(:note_types) || {"local" => "Local Note"}
  RIGHTS_STATEMENTS = Avalon::ControlledVocabulary.find_by_name(:rights_statements)

  set_terminology do |t|
    t.root(:path=>'mods',
      :xmlns => 'http://www.loc.gov/mods/v3',
      :namespace_prefix=>nil,
      :schema => 'http://www.loc.gov/standards/mods/v3/mods-3-4.xsd')

    t.identifier(:path => 'mods/oxns:identifier') do
      t.type_(:path => '@type', :namespace_prefix => nil)
    end

    # Titles
    t.title_info(:path => 'titleInfo') do
      t.non_sort(:path => 'nonSort')
      t.title
      t.subtitle(:path => 'subTitle')
    end
    t.main_title_info(:ref => :title_info, :path => 'titleInfo[@usage="primary"]')
    t.main_title(:proxy => [:main_title_info, :title])
    t.alternative_title_info(:ref => :title_info, :path => 'titleInfo[@type="alternative"]')
    t.alternative_title(:proxy => [:alternative_title_info, :title])
    t.translated_title_info(:ref => :title_info, :path => 'titleInfo[@type="translated"]')
    t.translated_title(:proxy => [:translated_title_info, :title])
    t.uniform_title_info(:ref => :title_info, :path => 'titleInfo[@type="uniform"]')
    t.uniform_title(:proxy => [:uniform_title_info, :title])

    # Creators and Contributors
    t.name(:path => 'mods/oxns:name') do
      t.type_(:path => '@type', :namespace_prefix => nil)
      t.name_part(:path => 'namePart')
      t.role do
        t.code(:path => 'roleTerm', :attributes => { :type => 'code' })
        t.text(:path => 'roleTerm', :attributes => { :type => 'text' })
      end
    end
    t._contributor_name(:ref => [:name], :path => 'mods/oxns:name[not(@usage) or @usage!="primary"]')
    t.contributor(:proxy => [:_contributor_name, :name_part])
    t._creator_name(:ref => [:name], :path => 'mods/oxns:name[oxns:role/oxns:roleTerm[@type="text"] = "Creator" or oxns:role/oxns:roleTerm[@type="code"] = "cre"]')
    t.creator(:proxy => [:_creator_name, :name_part])
    t._primary_creator_name(:ref => [:name], :path => 'mods/oxns:name[@usage="primary"]')
    t.primary_creator(:proxy => [:_creator_name, :name_part])

    t.statement_of_responsibility(:path => 'note', :attributes => { :type => 'statement of responsibility' })

    # Type and Genre
    t.resource_type(:path => 'typeOfResource')
    # TODO: Add authority info to genre
    t.genre

    # Publishing Info
    t.origin_info(:path => 'mods/oxns:originInfo') do
      t.publisher
      t.place_info(:path => 'place') do
        t.place_term(:path => 'placeTerm')
      end
      t.date_created(:path => 'dateCreated', :attributes => { :encoding => 'edtf' })
      t.date_issued(:path => 'dateIssued', :attributes => { :encoding => 'edtf' })
      t.copyright_date(:path => 'copyrightDate', :attributes => { :encoding => 'iso8601' })
    end
    t.publisher(:proxy => [:origin_info, :publisher])
    t.place_of_origin(:proxy => [:origin_info, :place_info, :place_term])
    t.date_created(:proxy => [:origin_info, :date_created])
    t.date_issued(:proxy => [:origin_info, :date_issued])
    t.copyright_date(:proxy => [:origin_info, :copyright_date])

    # Language
    t.language do
      t.code(:path => 'languageTerm', :attributes => { :type => 'code' })
      t.text(:path => 'languageTerm', :attributes => { :type => 'text' })
    end
    t.language_code(:proxy => [:language, :code])
    t.language_text(:proxy => [:language, :text])

    # Physical Description
    t.mime_physical_description(:path => 'mods/oxns:physicalDescription') do
      t.internet_media_type(:path => 'internetMediaType')
    end
    t.media_type(:proxy => [:mime_physical_description, :internet_media_type])

    t.original_related_item(:path => 'relatedItem', :attributes => { :type => 'original'}) do
      t.physical_description(:path => 'physicalDescription') { t.extent }
      t.other_identifier(:path => 'identifier') { t.type_(:path => '@type', :namespace_prefix => nil) }
    end
    t.physical_description(:proxy => [:original_related_item, :physical_description, :extent])
    t.other_identifier(:proxy => [:original_related_item, :other_identifier])

    # Summary and Notes
    t.abstract(:path => 'abstract')
    t.note {
      t.type_(:path => '@type', :namespace_prefix => nil)
    }

    # Subjects
    # NOTE: This is a catch-all definition that will allow the terminology to function, but
    # only one child element will be used per <subject/> instance.
    t.subject do
      t.topic
      t.geographic
      t.temporal
      t.occupation
      t.name(:ref => :name)
      t.title_info(:ref => :title_info)
    end
    t.topical_subject(:proxy => [:subject, :topic])
    t.geographic_subject(:proxy => [:subject, :geographic])
    t.temporal_subject(:proxy => [:subject, :temporal])
    t.occupation_subject(:proxy => [:subject, :occupation])
    t.person_subject(:proxy => [:subject, :name, :name_part], :path => 'subject/oxns:name[@type="personal"]/oxns:namePart')
    t.corporate_subject(:proxy => [:subject, :name, :name_part], :path => 'subject/oxns:name[@type="corporate"]/oxns:namePart')
    t.family_subject(:proxy => [:subject, :name, :name_part], :path => 'subject/oxns:name[@type="family"]/oxns:namePart')
    t.title_subject(:proxy => [:subject, :title_info, :title])

    t.related_item(:path => 'relatedItem[not(@type)]') do
      t.displayLabel(:path => {:attribute =>'displayLabel'}, :namespace_prefix => nil)
      t.location(:path => 'location') do
        t.url(:path => 'url')
      end
      t.identifier
      t.title_info(:ref => :title_info)
    end
    t.related_item_url(:proxy => [:related_item, :location, :url])
    t.related_item_label(:proxy => [:related_item, :displayLabel])
    t.collection(:proxy => [:related_item, :title_info, :title], :path => 'relatedItem[@type="host"]/oxns:titleInfo/oxns:title')

    t.series_related_item(:path => 'relatedItem', :attributes => { :type => 'series'}) do
      t.title_info(:ref => :title_info)
    end
    t.series(:proxy => [:series_related_item, :title_info, :title])

    t.location do
      t.url(:attributes => { :access => nil })
      t.url_with_context(:path => 'url', :attributes => { :access => 'object in context' })
    end
    t.location_url(:ref => [:location, :url])
    t.permalink(:ref => [:location, :url_with_context])

    t.usage(:path => 'accessCondition')
    t.terms_of_use(:path => 'accessCondition', :attributes => { :type => 'use and reproduction'})
    t.rights_statement(:path => 'accessCondition', :attributes => { :type => 'use and reproduction', :displayLabel => 'Rights Statement' })
    t.table_of_contents(:path => 'tableOfContents')
    t.access_restrictions(:path => 'accessCondition', :attributes => { :type => 'restrictions on access' })

    t.record_info(:path => 'recordInfo') do
      t.origin(:path => 'recordOrigin')
      t.content_source(:path => 'recordContentSource')
      t.creation_date(:path => 'recordCreationDate')
      t.change_date(:path => 'recordChangeDate')
      t.identifier(:path => "recordIdentifier[@source='Fedora4']") { t.source_(:path => '@source', :namespace_prefix => nil) }
      t.bibliographic_id(:path => "recordIdentifier[@source!='Fedora' and @source!='Fedora4']") { t.source_(:path => '@source', :namespace_prefix => nil) }
      t.language_of_cataloging(:path => 'languageOfCataloging') { t.language_term(:path => 'languageTerm') }
      t.language(:proxy => [:language_of_cataloging, :language_term])
    end
    t.record_origin(:proxy => [:record_info, :origin])
    t.record_source(:proxy => [:record_info, :content_source])
    t.record_creation_date(:proxy => [:record_info, :creation_date])
    t.record_change_date(:proxy => [:record_info, :change_date])
    t.record_identifier(:proxy => [:record_info, :identifier])
    t.record_language(:proxy => [:record_info, :language])
    t.bibliographic_id(:proxy => [:record_info, :bibliographic_id])
  end

  def self.xml_template
    now = Time.now
    builder = Nokogiri::XML::Builder.new do |xml|
    xml.mods("xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xmlns"=>"http://www.loc.gov/mods/v3",
        "xsi:schemaLocation"=>"http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd") {
      xml.originInfo
      xml.physicalDescription
      xml.recordInfo {
        xml.recordOrigin('Avalon Media System')
        xml.recordContentSource('IEN')
        xml.recordCreationDate(now.strftime('%Y%m%d'))
        xml.recordChangeDate(now.iso8601)
        xml.recordIdentifier('source' => 'Fedora4')
        xml.languageOfCataloging {
          xml.languageTerm('authority' => 'iso639-2b', 'type' => 'code') { xml.text('eng') }
        }
      }
    }
    end
    return builder.doc
  end

  def self.blank_template
    Nokogiri::XML <<-EOC
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd"/>
    EOC
  end

  def populate_from_catalog! bib_id, bib_id_label = nil
    bib_id.strip!
    if bib_id.present?
      bib_id_label ||= IDENTIFIER_TYPES.keys.first
      new_record = Avalon::BibRetriever.for(bib_id_label).get_record(bib_id)
      if new_record.present?
        old_resource_type = self.resource_type.dup
        old_media_type = self.media_type.dup
        old_other_identifier = self.other_identifier.type.zip(self.other_identifier)
        old_bibliographic_id = self.bibliographic_id.dup
        old_bibliographic_id_source = self.bibliographic_id.source.dup
        old_date_issued = date_issued.dup.first
        # replace old mods with newly imported mods
        self.ng_xml = Nokogiri::XML(new_record)
        # de-dupe imported values
        [:genre, :topical_subject, :geographic_subject, :temporal_subject,
         :occupation_subject, :person_subject, :corporate_subject, :family_subject,
         :title_subject].each do |field|
           self.send("#{field}=".to_sym, self.send(field).uniq)
        end
        # restore old media_type and resource_type
        old_media_type.each do |val|
          self.add_child_node(self.ng_xml.root, :media_type, val)
        end
        self.send("resource_type=", old_resource_type)
        # let template remove languages that aren't in the controlled vocabulary, and de-dupe
        languages = self.language.collect &:strip
        self.language = nil
        languages.uniq.each { |lang| self.add_language(lang) }
        # add new other identifiers and restore old other identifiers and remove the old bibliographic id
        new_other_identifier = self.other_identifier.type.zip(self.other_identifier)
        self.other_identifier = nil
        ((old_other_identifier | new_other_identifier)-(old_bibliographic_id_source.zip old_bibliographic_id)).each do |id_pair|
          self.add_other_identifier(id_pair[1], id_pair[0])
        end
        # if bib_import includes date_issued, use it. Otherwise use old_date_issued or 'unknown/unknown'
        add_date_issued(old_date_issued || 'unknown/unknown') if date_issued.blank?
      end
      # add new bibliographic_id as another other identifier and also as a the new bibliographic_id
      self.add_other_identifier(bib_id, bib_id_label) unless self.other_identifier.type.zip(self.other_identifier).include?([bib_id_label, bib_id])
      self.bibliographic_id = nil
      self.add_bibliographic_id(bib_id, bib_id_label)
    end

    # Filter out notes that are not in the configured controlled vocabulary
    notezip = note.zip note.type
    self.note = nil
    notezip.each { |n| self.add_child_node self.ng_xml.root, :note, n[0], n[1] if NOTE_TYPES.include? n[1] }

  end
end
