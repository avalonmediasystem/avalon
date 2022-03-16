# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

module ModsBehaviors

  def prefix(opts)
    ""
  end

  def to_solr(solr_doc = Hash.new, opts = {})
    solr_doc = super(solr_doc)

    solr_doc['title_tesi'] = self.find_by_terms(:main_title).text

    # Specific fields for Blacklight export

    # Title fields
    addl_titles = [[:main_title_info, :subtitle],
        :alternative_title, [:alternative_title_info, :subtitle],
        :translated_title, [:translated_title_info, :subtitle],
        :uniform_title, [:uniform_title_info, :subtitle]].collect do |addl_title|
      self.find_by_terms(*addl_title)
    end
    solr_doc['title_addl_sim'] = gather_terms(addl_titles)
    solr_doc['heading_sim'] = self.find_by_terms(:main_title).text


    solr_doc['creator_ssim'] = gather_terms(self.find_by_terms(:creator))
#    solr_doc['creator_ssi'] = self.find_by_terms(:creator).text
    # Individual fields
    solr_doc['summary_ssi'] = self.find_by_terms(:abstract).text
    solr_doc['publisher_sim'] = gather_terms(self.find_by_terms(:publisher))
    solr_doc['contributor_sim'] = gather_terms(self.find_by_terms(:contributor))
    solr_doc['subject_sim'] = gather_terms(self.find_by_terms(:subject))
    solr_doc['genre_sim'] = gather_terms(self.find_by_terms(:genre))
#    solr_doc['physical_dtl_sim'] = gather_terms(self.find_by_terms(:format))
#    solr_doc['contents_sim'] = gather_terms(self.find_by_terms(:parts_list))
    solr_doc['notes_sim'] = gather_terms(self.find_by_terms(:note))
    solr_doc['table_of_contents_sim'] = gather_terms(self.find_by_terms(:table_of_contents))
    solr_doc['access_sim'] = gather_terms(self.find_by_terms(:usage))
#    solr_doc['collection_sim'] = gather_terms(self.find_by_terms(:archival_collection))
    #filter formats based upon whitelist
    solr_doc['format_sim'] = (gather_terms(self.find_by_terms(:resource_type)) & ['moving image', 'sound recording' ]).map(&:titleize)
    solr_doc['location_sim'] = gather_terms(self.find_by_terms(:geographic_subject))

    # Blacklight facets - these are the same facet fields used in our Blacklight app
    # for consistency and so they'll show up when we export records from Hydra into BL:
    solr_doc['material_sim'] = "Digital"
    solr_doc['subject_topic_sim'] = gather_terms(self.find_by_terms(:topical_subject))
    solr_doc['subject_geographic_sim'] = gather_terms(self.find_by_terms(:geographic_subject))
    solr_doc['subject_temporal_sim'] = gather_terms(self.find_by_terms(:temporal_subject))
    solr_doc['subject_occupation_sim'] = gather_terms(self.find_by_terms(:occupation_subject))
    solr_doc['subject_person_sim'] = gather_terms(self.find_by_terms(:person_subject))
    solr_doc['subject_corporate_sim'] = gather_terms(self.find_by_terms(:corporate_subject))
    solr_doc['subject_family_sim'] = gather_terms(self.find_by_terms(:family_subject))
    solr_doc['subject_title_sim'] = gather_terms(self.find_by_terms(:title_subject))
    solr_doc['time_sim'] = gather_terms(self.find_by_terms(:temporal_subject))

    # TODO: map PBcore's three-letter language codes to full language names
    # Right now, everything's English.
    solr_doc['language_sim'] = gather_terms(self.find_by_terms(:language_text))
    solr_doc['language_code_sim'] = gather_terms(self.find_by_terms(:language_code))
    solr_doc['physical_description_sim'] = gather_terms(self.find_by_terms(:physical_description))
    solr_doc['related_item_url_sim'] = gather_terms(self.find_by_terms(:related_item_url))
    solr_doc['related_item_label_sim'] = gather_terms(self.find_by_terms(:related_item_label))
    solr_doc['terms_of_use_si'] = (self.find_by_terms(:terms_of_use) - self.find_by_terms(:rights_statement)).text
    solr_doc['rights_statement_ssi'] = self.find_by_terms(:rights_statement).text
    solr_doc['other_identifier_sim'] = gather_terms(self.find_by_terms(:other_identifier))

    # Extract 4-digit year for creation date facet in Hydra and pub_date facet in Blacklight
    solr_doc['date_ssi'] = self.find_by_terms(:date_issued).text
    solr_doc['date_created_ssi'] = self.find_by_terms(:date_created).text
    # Put both publication date and creation date into the date facet
    solr_doc['date_sim'] = gather_years(solr_doc['date_ssi'])
    solr_doc['date_sim'] += gather_years(solr_doc['date_created_ssi']) if solr_doc['date_created_ssi'].present?

    # For full text, we stuff it into the mods_tesim field which is already configured for Mods doucments
    solr_doc['mods_tesim'] = self.ng_xml.xpath('//text()').collect { |t| t.text }

    # TODO: Find a better way to handle super long fields other than simply dropping them from the solr doc.
    solr_doc.delete_if do |field,value|
      case value
      when String
        value.length > 32000
      when Array
        value.reject! { |t| t.length > 32000 }
        false
      else false
      end
    end

    return solr_doc
  end

  def ns
    { 'mods' => 'http://www.loc.gov/mods/v3' }
  end

  def ensure_identifier_exists!(f4_id)
    self.send(:add_record_identifier, f4_id) if self.record_identifier.empty? or self.record_identifier.join.empty?
  end

  def update_change_date!(t=Time.now.iso8601)
    self.record_change_date = t
  end

  def ensure_root_term_exists!(term)
    if find_by_terms(term).empty?
      ng_xml.root.add_child("<#{term.to_s.camelcase(first_letter = :lower)}/>")
    end
  end

  def remove_empty_nodes!
    self.ng_xml.xpath('//mods:name[count(mods:namePart)=0]',ns).each &:remove

    pattern = '//*[namespace-uri()="http://www.loc.gov/mods/v3"][count(*)=0 and normalize-space(text())=""]'
    empty_nodes = self.ng_xml.xpath(pattern, ns)
    while empty_nodes.length > 0
      empty_nodes.each &:remove
      empty_nodes = self.ng_xml.xpath(pattern, ns)
    end
    serialize!
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
      'mods:mods/mods:table_of_contents',
      'mods:mods/mods:note',
      'mods:mods/mods:subject',
      'mods:mods/mods:relatedItem',
      'mods:mods/mods:location',
      'mods:mods/mods:accessCondition',
      'mods:mods/mods:recordInfo',
      'mods:mods/*'
    ]

    new_doc = self.class.blank_template
    order.each do |node|
      self.ng_xml.xpath(node, ns).each do |element|
        new_doc.root.add_child(element.clone)
        element.remove
      end
    end

    self.ng_xml = new_doc
    serialize!
  end

  def permalink=(url)
    if node_exists? :permalink
      update_values([:permalink]=>{0=>url})
    else
      add_permalink(url)
    end
  end

  private

  def gather_terms(terms)
    terms.collect { |r| r.text }.compact.uniq
  end

  def gather_years(date)
    parsed = Date.edtf(date)
    return Array.new if parsed.nil?
    years =
      if (parsed.respond_to?(:unknown?) && parsed.unknown?) || (parsed.class == EDTF::Unknown)
        ['Unknown']
      elsif parsed.respond_to?(:map)
        parsed.map(&:year_precision!)
        parsed.map(&:year)
      elsif parsed.unspecified?(:year)
        parsed.precision = :year
        if parsed.unspecified.year[2]
          EDTF::Interval.new(parsed, parsed.next(99).last).map(&:year)
        elsif parsed.unspecified.year[3]
          EDTF::Interval.new(parsed, parsed.next(9).last).map(&:year)
        end
      else
        parsed.year_precision!
        Array(parsed.year)
      end
    years.map(&:to_s).uniq
  end

  # Override NokogiriDatastream#update_term_values to use the explicit
  # template setter on a TemplateMissingException error
  def update_indexed_attributes(params={}, opts={})
    result = nil
    begin
      result = super
    rescue OM::XML::TemplateMissingException
      if params.length == 1 and params.keys.first.length == 1
        params.each_pair do |attribute, value|
          method = "add_#{attribute.first.to_s}".to_sym
          result = self.send(method, value)
        end
      else
        raise
      end
    end
    return result
  end

 end
