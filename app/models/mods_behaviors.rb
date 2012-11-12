module ModsBehaviors

  def to_solr(solr_doc=SolrDocument.new)
    super(solr_doc)

    solr_doc[:title_t] = self.find_by_terms(:main_title).text

    # Specific fields for Blacklight export

    # Title fields
    solr_doc[:title_display] = self.find_by_terms(:main_title).text
    addl_titles = [[:main_title_info, :subtitle], 
    		:alternative_title, [:alternative_title_info, :subtitle], 
	    	:translated_title, [:translated_title_info, :subtitle], 
	    	:uniform_title, [:uniform_title_info, :subtitle]].collect do |addl_title| 
      self.find_by_terms(*addl_title)
    end
    solr_doc[:title_addl_display] = gather_terms(addl_titles)
    solr_doc[:heading_display] = self.find_by_terms(:main_title).text


    solr_doc[:creator_display] = self.find_by_terms(:creator).text
    # Individual fields
    solr_doc[:summary_display] = self.find_by_terms(:abstract).text
    solr_doc[:publisher_display] = gather_terms(self.find_by_terms(:publisher))
    solr_doc[:contributors_display] = gather_terms(self.find_by_terms(:contributor))
    solr_doc[:subject_display] = gather_terms(self.find_by_terms(:subject))
    solr_doc[:genre_display] = gather_terms(self.find_by_terms(:genre))
#    solr_doc[:physical_dtl_display] = gather_terms(self.find_by_terms(:format))
#    solr_doc[:contents_display] = gather_terms(self.find_by_terms(:parts_list))
    solr_doc[:notes_display] = gather_terms(self.find_by_terms(:note))
    solr_doc[:access_display] = gather_terms(self.find_by_terms(:usage))
#    solr_doc[:collection_display] = gather_terms(self.find_by_terms(:archival_collection))
    solr_doc[:format_display] = gather_terms(self.find_by_terms(:media_type))
    solr_doc[:location_display] = gather_terms(self.find_by_terms(:geographic_subject))

    # Blacklight facets - these are the same facet fields used in our Blacklight app
    # for consistency and so they'll show up when we export records from Hydra into BL:
    solr_doc[:material_facet] = "Digital"
    solr_doc[:genre_facet] = gather_terms(self.find_by_terms(:genre))
    solr_doc[:contributor_facet] = gather_terms(self.find_by_terms(:contributor))
    solr_doc[:creator_facet] = gather_terms(self.find_by_terms(:creator))
    solr_doc[:publisher_facet] = gather_terms(self.find_by_terms(:publisher))
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
    solr_doc[:time_facet] = gather_terms(self.find_by_terms(:temporal_subject))

    # TODO: map PBcore's three-letter language codes to full language names
    # Right now, everything's English.
    solr_doc[:language_facet] = self.find_by_terms(:language_text).text
    solr_doc[:language_display] = self.find_by_terms(:language_text).text

    # Extract 4-digit year for creation date facet in Hydra and pub_date facet in Blacklight
    create = self.find_by_terms(:date_created).text.strip
    unless create.nil? or create.empty?
      solr_doc[:create_date_facet] = get_year(create)
      solr_doc[:pub_date] = get_year(create)
    end

    # For full text, we stuff it into the mods_t field which is already configured for Mods doucments
    solr_doc[:mods_t] = self.ng_xml.xpath('//text()').collect { |t| t.text }

    return solr_doc
  end

  def ns
  	{ 'mods' => 'http://www.loc.gov/mods/v3' }
	end

  def ensure_identifier_exists!
    self.identifier = self.pid if self.identifier.empty?
  end

  def update_change_date!(t=Time.now.iso8601)
    self.record_change_date = t
  end

  def remove_empty_nodes!
  	patterns = [
  		'//mods:titleInfo[count(mods:title)=0]',
  		'//mods:name[count(mods:namePart)=0]',
  		'//mods:subject[count(*)=0]',
  		'//mods:language[count(mods:languageTerm)=0]'
  	]

  	patterns.each do |path|
  		self.ng_xml.xpath(path, ns).each { |node| node.remove }
  	end
  end

  def reorder_elements!
    order = [
      'mods:mods/mods:titleInfo[@usage="primary"]',
      'mods:mods/mods:titleInfo[@type="alternative"]',
      'mods:mods/mods:titleInfo[@type="translated"]',
      'mods:mods/mods:titleInfo[@type="uniform"]',
      'mods:mods/mods:titleInfo',
      'mods:mods/mods:name[@usage="primary"]',
      'mods:mods/mods:name',
      'mods:mods/mods:typeOfResource',
      'mods:mods/mods:genre',
      'mods:mods/mods:originInfo',
      'mods:mods/mods:language',
      'mods:mods/mods:physicalDescription',
      'mods:mods/mods:abstract',
      'mods:mods/mods:note',
      'mods:mods/mods:subject',
      'mods:mods/mods:relatedItem',
      'mods:mods/mods:identifier',
      'mods:mods/mods:location',
      'mods:mods/mods:accessCondition',
      'mods:mods/mods:recordInfo',
      'mods:mods/*'
    ]

    remove_empty_nodes!
    new_doc = self.class.blank_template
    order.each do |node|
      self.ng_xml.xpath(node, ns).each do |element|
        new_doc.root.add_child(element.clone)
        element.remove
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