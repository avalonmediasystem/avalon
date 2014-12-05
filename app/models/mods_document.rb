# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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

class ModsDocument < ActiveFedora::OmDatastream
  
  include ModsTemplates
  include ModsBehaviors

  set_terminology do |t|
    t.root(:path=>'mods',
      :xmlns => 'http://www.loc.gov/mods/v3', 
      :namespace_prefix=>nil,
      :schema => 'http://www.loc.gov/standards/mods/v3/mods-3-4.xsd')

    t.identifier(:path => 'mods/oxns:identifier') do
      t.type_(:path => '@type', :namespace_prefix => nil)
    end
    t.bibliographic_id(:proxy => [:identifier])
    t.bibliographic_id_label(:proxy => [:identifier, :type])

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
    t.name(:path => 'name') do
      t.type_(:path => '@type', :namespace_prefix => nil)
      t.name_part(:path => 'namePart')
      t.role do
        t.code(:path => 'roleTerm', :attributes => { :type => 'code' })
        t.text(:path => 'roleTerm', :attributes => { :type => 'text' })
      end
    end
    t._contributor_name(:ref => [:name], :path => 'name[not(@usage) or @usage!="primary"]')
    t.contributor(:proxy => [:_contributor_name, :name_part])
    t._creator_name(:ref => [:name], :path => 'name[oxns:role/oxns:roleTerm[@type="text"] = "Creator" or oxns:role/oxns:roleTerm[@type="code"] = "cre"]')
    t.creator(:proxy => [:_creator_name, :name_part])
    t._primary_creator_name(:ref => [:name], :path => 'name[@usage="primary"]')
    t.primary_creator(:proxy => [:_creator_name, :name_part])

    t.statement_of_responsibility(:path => 'note', :attributes => { :type => 'statement of responsbility' })

    # Type and Genre
    t.resource_type(:path => 'typeOfResource')
    # TODO: Add authority info to genre
    t.genre

    # Publishing Info
    t.origin_info(:path => 'originInfo') do
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
      t.physical_description(:path => 'physicalDescription') do
        t.extent
      end
    end
    t.physical_description(:proxy => [:original_related_item, :physical_description, :extent])

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

    t.location do
      t.url(:attributes => { :access => nil })
      t.url_with_context(:path => 'url', :attributes => { :access => 'object in context' })
    end
    t.location_url(:ref => [:location, :url])
    t.permalink(:ref => [:location, :url_with_context])

    t.usage(:path => 'accessCondition')
    t.terms_of_use(:path => 'accessCondition', :attributes => { :type => 'use and reproduction' })
    t.access_restrictions(:path => 'accessCondition', :attributes => { :type => 'restrictions on access' })

    t.record_info(:path => 'recordInfo') do
      t.origin(:path => 'recordOrigin')
      t.content_source(:path => 'recordContentSource')
      t.creation_date(:path => 'recordCreationDate')
      t.change_date(:path => 'recordChangeDate')
      t.identifier(:path => 'recordIdentifier')
      t.language_of_cataloging(:path => 'languageOfCataloging') { t.language_term(:path => 'languageTerm') }
      t.language(:proxy => [:language_of_cataloging, :language_term])
    end
    t.record_origin(:proxy => [:record_info, :origin])
    t.record_source(:proxy => [:record_info, :content_source])
    t.record_creation_date(:proxy => [:record_info, :creation_date])
    t.record_change_date(:proxy => [:record_info, :change_date])
    t.record_identifier(:proxy => [:record_info, :identifier])
    t.record_language(:proxy => [:record_info, :language])
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
        xml.recordIdentifier('source' => 'Fedora')
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

end
