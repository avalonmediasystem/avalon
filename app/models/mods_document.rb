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
    t.main_title_info(:ref => :title_info, :path => 'titleInfo[count(@type)=0]')
    t.alternative_title_info(:ref => :title_info, :path => 'titleInfo[@type="alternative"]')
    t.translated_title_info(:ref => :title_info, :path => 'titleInfo[@type="translated"]')
    t.uniform_title_info(:ref => :title_info, :path => 'titleInfo[@type="uniform"]')
    t.main_title(:proxy => [:main_title_info, :title])
    t.alternative_title(:proxy => [:alternative_title_info, :title])
    t.translated_title(:proxy => [:translated_title_info, :title])
    t.uniform_title(:proxy => [:uniform_title_info, :title])

    # Creators and Contributors
    t.name(:path => 'name') do
      t.name_part(:path => 'namePart')
      t.role do
        t.code(:path => 'roleTerm', :attributes => { :type => 'code' })
        t.text(:path => 'roleTerm', :attributes => { :type => 'text' })
      end
    end
    t._personal_name(:ref => :name, :path => 'name[@type="personal"]')
    t.personal_name(:proxy => [:_personal_name, :name_part])
    t._corporate_name(:ref => :name, :path => 'name[@type="corporate"]')
    t.corporate_name(:proxy => [:_corporate_name, :name_part])
    t._family_name(:ref => :name, :path => 'name[@type="family"]')
    t.family_name(:proxy => [:_corporate_name, :name_part])
    t.contributor_name(:proxy => [:name, :name_part])
    t._creator_name(:ref => [:name], :path => 'name[oxns:role/oxns:roleTerm[@type="text"] = "Creator" or oxns:role/oxns:roleTerm[@type="code"] = "cre"]')
    t.creator_name(:proxy => [:_creator_name, :name_part])

    # Type and Genre
    t.resource_type(:path => 'typeOfResource')
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
    t.publisher_name(:proxy => [:origin_info, :publisher])
    t.place_of_origin(:proxy => [:origin_info, :place_info, :place_term])
    t.creation_date(:proxy => [:origin_info, :date_created])
    t.issue_date(:proxy => [:origin_info, :date_issued])
    t.copyright_date(:proxy => [:origin_info, :copyright_date])

    # Language
    t.language do
      t.code(:path => 'languageTerm', :attributes => { :type => 'code' })
      t.text(:path => 'languageTerm', :attributes => { :type => 'text' })
    end
    t.language_code(:proxy => [:language, :code])
    t.language_text(:proxy => [:language, :text])

    # Physical Description
    t.physical_description(:path => 'physicalDescription') do
      t.internet_media_type(:path => 'internetMediaType')
    end
    t.media_type(:proxy => [:physical_description, :internet_media_type])

    t.summary(:path => 'abstract')

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

    t.usage(:path => 'accessCondition')
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
    t.record_origin(:proxy => [:record_info, :origin])
    t.record_source(:proxy => [:record_info, :content_source])
    t.record_creation_date(:proxy => [:record_info, :creation_date])
    t.record_change_date(:proxy => [:record_info, :change_date])
    t.record_identifier(:proxy => [:record_info, :identifier])
    t.record_language(:proxy => [:record_info, :language])
  end

  def self.delegate_to_template(xml, template, *args)
    if xml.is_a?(Nokogiri::XML::Builder)
      xml = xml.doc.root
    elsif xml.is_a?(Nokogiri::XML::Document)
      xml = xml.root
    end
    xml.add_child(template_registry.instantiate(template, *args))
  end

  # Title Templates
  define_template :title_info do |xml, title, subtitle=nil, type=nil|
    attrs = type.present? ? { :type => type.to_s } : {}
    xml.titleInfo(attrs) {
      xml.title(title)
      xml.subTitle(subtitle) unless subtitle.nil?
    }
  end
  define_template(:title)             { |xml, *args| delegate_to_template(xml, :title_info, *args, nil)          }
  define_template(:alternative_title) { |xml, *args| delegate_to_template(xml, :title_info, *args, :alternative) }
  define_template(:translated_title)  { |xml, *args| delegate_to_template(xml, :title_info, *args, :translated)  }
  define_template(:uniform_title)     { |xml, *args| delegate_to_template(xml, :title_info, *args, :uniform)     }

  # Name Templates
  define_template :name do |xml, type, name, role_code='cre', role_text='Creator'|
    xml.name(:type => type) {
      xml.namePart(name)
      if (role_code.present? or role_text.present?)
        xml.role {
          xml.roleTerm(:authority => 'marcrelator', :type => 'code') { xml.text(role_code) } if role_code.present?
          xml.roleTerm(:authority => 'marcrelator', :type => 'text') { xml.text(role_text) } if role_text.present?
        }
      end
    }
  end
  define_template(:personal_name)  { |xml, *args| delegate_to_template(xml, :name, :personal,  *args) }
  define_template(:corporate_name) { |xml, *args| delegate_to_template(xml, :name, :corporate, *args) }
  define_template(:family_name)    { |xml, *args| delegate_to_template(xml, :name, :family,    *args) }

  # Simple Subject Templates
  define_template(:simple_subject)     { |xml, type, text| xml.subject { xml.send(type.to_sym, text) } }
  define_template(:topical_subject)    { |xml, *args| delegate_to_template(xml, :simple_subject, :topic,      *args) }
  define_template(:geographic_subject) { |xml, *args| delegate_to_template(xml, :simple_subject, :geographic, *args) }
  define_template(:temporal_subject)   { |xml, *args| delegate_to_template(xml, :simple_subject, :temporal,   *args) }
  define_template(:occupation_subject) { |xml, *args| delegate_to_template(xml, :simple_subject, :occupation, *args) }

  # Complex Subject Templates
  define_template(:name_subject)      { |xml, type, name| xml.subject; delegate_to_template(xml.doc.root.children.first, :name, type, name) }
  define_template(:person_subject)    { |xml, name| delegate_to_tepmlate(xml, :name_subject, :personal, name)  }
  define_template(:corporate_subject) { |xml, name| delegate_to_tepmlate(xml, :name_subject, :corporate, name) }
  define_template(:family_subject)    { |xml, name| delegate_to_tepmlate(xml, :name_subject, :family, name)    }


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

  def to_solr(solr_doc=SolrDocument.new)
    super(solr_doc)

    solr_doc[:title_t] = self.find_by_terms(:main_title).text

    # Specific fields for Blacklight export

    # Title fields
    solr_doc[:title_display] = self.find_by_terms(:main_title).text
    addl_titles = [[:main_title_info, :subtitle], :alternative_title, :translated_title, :uniform_title].collect do |addl_title| 
      self.find_by_terms(*addl_title)
    end
    solr_doc[:title_addl_display] = gather_terms(addl_titles)
    solr_doc[:heading_display] = self.find_by_terms(:main_title).text

    # Individual fields
    solr_doc[:summary_display] = self.find_by_terms(:summary).text
    solr_doc[:publisher_display] = gather_terms(self.find_by_terms(:publisher_name))
    solr_doc[:contributors_display] = gather_terms(self.find_by_terms(:contributor_name))
    solr_doc[:subject_display] = gather_terms(self.find_by_terms(:subject))
    solr_doc[:genre_display] = gather_terms(self.find_by_terms(:genre))
#    solr_doc[:physical_dtl_display] = gather_terms(self.find_by_terms(:format))
#    solr_doc[:contents_display] = gather_terms(self.find_by_terms(:parts_list))
#    solr_doc[:notes_display] = gather_terms(self.find_by_terms(:note))
    solr_doc[:access_display] = gather_terms(self.find_by_terms(:usage))
#    solr_doc[:collection_display] = gather_terms(self.find_by_terms(:archival_collection))
    solr_doc[:format_display] = gather_terms(self.find_by_terms(:media_type))

    # Blacklight facets - these are the same facet fields used in our Blacklight app
    # for consistency and so they'll show up when we export records from Hydra into BL:
    solr_doc[:material_facet] = "Digital"
    solr_doc[:genre_facet] = gather_terms(self.find_by_terms(:genre))
    solr_doc[:contributor_facet] = gather_terms(self.find_by_terms(:contributor_name))
    solr_doc[:publisher_facet] = gather_terms(self.find_by_terms(:publisher_name))
    solr_doc[:subject_topic_facet] = gather_terms(self.find_by_terms(:topical_subject))
    solr_doc[:subject_geographic_facet] = gather_terms(self.find_by_terms(:geographic_subject))
    solr_doc[:subject_temporal_facet] = gather_terms(self.find_by_terms(:temporal_subject))
    solr_doc[:subject_occupation_facet] = gather_terms(self.find_by_terms(:occupation_subject))
    solr_doc[:subject_person_facet] = gather_terms(self.find_by_terms(:person_subject))
    solr_doc[:subject_corporate_facet] = gather_terms(self.find_by_terms(:corporate_subject))
    solr_doc[:subject_family_facet] = gather_terms(self.find_by_terms(:family_subject))
    solr_doc[:subject_title_facet] = gather_terms(self.find_by_terms(:title_subject))
    solr_doc[:format_facet] = gather_terms(self.find_by_terms(:media_type))
    solr_doc[:location_facet] = gather_terms(self.find_by_terms(:geographic_subject))
#    solr_doc[:time_facet] = gather_terms(self.find_by_terms(:temporal))

    # TODO: map PBcore's three-letter language codes to full language names
    # Right now, everything's English.
    solr_doc[:language_facet] = self.find_by_terms(:language_text).text
    solr_doc[:language_display] = self.find_by_terms(:language_text).text

    # Extract 4-digit year for creation date facet in Hydra and pub_date facet in Blacklight
    create = self.find_by_terms(:creation_date).text.strip
    unless create.nil? or create.empty?
      solr_doc[:create_date_facet] = get_year(create)
      solr_doc[:pub_date] = get_year(create)
    end

    # For full text, we stuff it into the mods_t field which is already configured for Mods doucments
    solr_doc[:mods_t] = self.ng_xml.xpath('//text()').collect { |t| t.text }

    return solr_doc
  end

  def self.blank_template
    Nokogiri::XML <<-EOC
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd"/>
    EOC
  end

  def reorder_elements
    ns = { 'mods' => 'http://www.loc.gov/mods/v3' }
    order = [
      'mods:mods/mods:titleInfo[count(@type)=0]',
      'mods:mods/mods:titleInfo[@type="alternative"]',
      'mods:mods/mods:titleInfo[@type="translated"]',
      'mods:mods/mods:titleInfo[@type="uniform"]',
      'mods:mods/mods:name',
      'mods:mods/mods:typeOfResource',
      'mods:mods/mods:genre',
      'mods:mods/mods:originInfo',
      'mods:mods/mods:language',
      'mods:mods/mods:physicalDescription',
      'mods:mods/mods:abstract',
      'mods:mods/mods:subject',
      'mods:mods/mods:relatedItem',
      'mods:mods/mods:identifier',
      'mods:mods/mods:location',
      'mods:mods/mods:accessCondition',
      'mods:mods/mods:recordInfo'
    ]


    new_doc = self.class.blank_template
    order.each do |node|
      puts node
      self.ng_xml.xpath(node, ns).each do |element|
        puts "  #{element.name}"
        new_doc.root.add_child(element.clone)        
      end
    end
    self.ng_xml = new_doc
  end

  private

  def gather_terms(terms)
    terms.collect { |r| r.text }.compact.uniq
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