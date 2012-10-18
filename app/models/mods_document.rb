class ModsDocument < ActiveFedora::NokogiriDatastream

  set_terminology do |t|
    t.root(:path=>'mods',
      :xmlns => 'http://www.loc.gov/mods/v3', 
      :namespace_prefix=>nil,
      :schema => 'http://www.loc.gov/standards/mods/v3/mods-3-4.xsd')

    # Titles
    t.title_info(:path => 'titleInfo') do
      t.title
      t.subtitle(:path => 'subTitle')
    end
    t.main_title(:ref => :title_info, :path => 'titleInfo[empty(@type)]')
    t.alternative_title(:ref => :title_info, :path => 'titleInfo[@type=""]')
    t.translated_title(:ref => :title_info, :path => 'titleInfo[@type=""]')
    t.uniform_title(:ref => :title_info, :path => 'titleInfo[@type=""]')

    # Creators and Contributors
    t.name(:path => 'name') do
      t.name_part(:path => 'namePart')
      t.role do
        t.relator_code(:path => 'roleTerm', :attributes => { :type => 'code' })
        t.relator_text(:path => 'roleTerm', :attributes => { :type => 'text' })
      end
    end
    t.personal_name(:ref => :name, :path => 'name[@type="personal"]')
    t.corporate_name(:ref => :name, :path => 'name[@type="corporate"]')

    # Type and Genre
    t.resource_type(:path => 'typeOfResource')
    t.genre

    # Publishing Info
    t.origin_info(:path => 'originInfo') do
      t._place(:path => 'place') do
        t._place_term(:path => 'placeTerm')
      end
      t.place(:proxy => [:_place, :_place_term])
      t.date_created(:path => 'dateCreated')
      t.date_issued(:path => 'dateIssued')
      t.copyright_date(:path => 'copyrightDate')
    end

    # Language
    t.language do
      t.language_text(:path => 'languageTerm', :attributes => { :type => 'text' })
      t.language_code(:path => 'languageTerm', :attributes => { :type => 'code' })
    end

    # Physical Description
    t.physical_description(:path => 'physicalDescription') do
      t.internet_media_type(:path => 'internetMediaType')
    end
    t.mime_type(:proxy => [:physical_description, :internet_media_type])

    t.abstract

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
    t.person_subject(:proxy => [:subject, :name], :path => 'subject/oxns:name[@type="personal"]')
    t.corporate_subject(:proxy => [:subject, :name], :path => 'subject/oxns:name[@type="corporate"]')
    t.family_subject(:proxy => [:subject, :name], :path => 'subject/oxns:name[@type="family"]')
    t.title_subject(:proxy => [:subject, :title_info])

    t.related_item(:path => 'relatedItem') do
      t.identifier
    end
    t.related_item_id(:proxy => [:related_item, :identifier])

    t.identifier

    t.location do
      t.url
    end
    t.location_url(:proxy => [:location, :url])

    t.reproduction_notes(:path => 'accessCondition', :attributes => { :type => 'use and reproduction' })
    t.restrictions(:path => 'accessCondition', :attributes => { :type => 'restrictions on access' })

    t.record_info(:path => 'recordInfo') do
      t.origin(:path => 'recordOrigin')
      t.content_source(:path => 'recordContentSource')
      t.creation_date(:path => 'recordCreationDate')
      t.change_date(:path => 'recordChangeDate')
      t.identifier(:path => 'recordIdentifier')
      t.language_of_cataloging(:path => 'languageOfCataloging') { t.language_term(:path => 'languageTerm') }
      t.language(:proxy => [:language_of_cataloging, :language_term])
    end
  end

  define_template :title_info do |xml, title, subtitle=nil, type=nil|
    attrs = type.present? ? { :type => type.to_s } : {}
    xml.titleInfo(attrs) {
      xml.title(title)
      xml.subTitle(subtitle) unless subtitle.nil?
    }
  end
  define_template(:title)             { |xml, *args| xml.doc.root.add_child(template_registry.instantiate(:title_info, *args, nil))}
  define_template(:alternative_title) { |xml, *args| xml.doc.root.add_child(template_registry.instantiate(:title_info, *args, :alternative)) }
  define_template(:translated_title)  { |xml, *args| xml.doc.root.add_child(template_registry.instantiate(:title_info, *args, :translated))  }
  define_template(:uniform_title)     { |xml, *args| xml.doc.root.add_child(template_registry.instantiate(:title_info, *args, :uniform))     }

  define_template :name do |xml, type, name, role_code, role_text|
    xml.name(:type => type) {
      xml.namePart(name)
      xml.role {
        xml.roleTerm(:authority => 'marcrelator', :type => 'code') { xml.text(role_code) }
        xml.roleTerm(:authority => 'marcrelator', :type => 'text') { xml.text(role_text) }
      }
    }
  end
  define_template(:personal_name)  { |xml, *args| xml.doc.root.add_child(template_registry.instantiate(:name, :personal,  *args)) }
  define_template(:corporate_name) { |xml, *args| xml.doc.root.add_child(template_registry.instantiate(:name, :corporate, *args)) }
  define_template(:family_name)    { |xml, *args| xml.doc.root.add_child(template_registry.instantiate(:name, :family,    *args)) }

  def self.xml_template
    now = Time.now
    builder = Nokogiri::XML::Builder.new do |xml|
    xml.mods("xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xmlns"=>"http://www.loc.gov/mods/v3",
        "xsi:schemaLocation"=>"http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd") {
      xml.titleInfo {
        xml.title
      }
      xml.originInfo {
        xml.place {
          xml.placeTerm
        }
        xml.dateCreated('encoding'=>'edtf')
      }
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

end