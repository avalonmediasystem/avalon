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

module ModsTemplates
  extend ActiveSupport::Concern

  included do
    class_eval do

      # Title Templates
      define_template :title_info do |xml, title, attributes={}|
        opts = { primary: false }.merge(attributes)
        attrs = opts[:type].present? ? { :type => opts[:type].to_s } : {}
        attrs['usage']="primary" if opts[:primary]
        xml.titleInfo(attrs) {
          xml.title(title)
          xml.subTitle(opts[:subtitle]) if opts[:subtitle].present?
        }
      end

      define_template :_identifier do |xml,text,type|
        xml.identifier(:type => type) { xml.text(text) }
      end
      def add_identifier(content, attrs={})
        (type,text) = content.is_a?(Array) ? content : ['Other',content]
        add_child_node(ng_xml.root, :_identifier, text, type)
      end


      def add_title(title, attrs={}, defaults={})
        add_child_node(ng_xml.root, :title_info, title, defaults.merge(attrs))
      end
      def add_main_title(title, attrs={});        add_title(title, attrs, primary: true);      end
      def add_alternative_title(title, attrs={}); add_title(title, attrs, type: :alternative); end
      def add_translated_title(title, attrs={});  add_title(title, attrs, type: :translated);  end
      def add_uniform_title(title, attrs={});     add_title(title, attrs, type: :uniform);     end

      define_template :origin_info_child do |xml, type, value, attributes={}|
        xml.send(type, attributes) { xml.text value }
      end

      def get_origin_info
        node = find_by_terms(:origin_info).first
        if node.nil?
          node = ng_xml.root.add_child('<originInfo/>')
        end
        node
      end

      def add_origin_info(type, value, attrs={})
        add_child_node(get_origin_info, :origin_info_child, type, value, attrs)
      end

      def add_publisher(value, attrs={})
        add_origin_info(:publisher, value)
      end

      def add_date_created(value, attrs={})
        add_origin_info(:dateCreated, value, { :encoding => 'edtf' })
      end

      def add_date_issued(value, attrs={})
        add_origin_info(:dateIssued, value, { :encoding => 'edtf' })
      end

      def add_copyright_date(value, attrs={})
        add_origin_info(:copyrightDate, value, { :encoding => 'iso8601' })
      end

      # Name Templates
      define_template :name do |xml, name, attributes|
        opts = { type: 'personal', role_code: 'ctb', role_text: 'Contributor', primary: false }.merge(attributes)
        attrs = { :type => opts[:type] }
        attrs['usage']="primary" if opts[:primary]
        xml.name(attrs) {
          xml.namePart { xml.text(name) }
          if (opts[:role_code].present? or opts[:role_text].present?)
            xml.role {
              xml.roleTerm(:authority => 'marcrelator', :type => 'code') { xml.text(opts[:role_code]) } if opts[:role_code].present?
              xml.roleTerm(:authority => 'marcrelator', :type => 'text') { xml.text(opts[:role_text]) } if opts[:role_text].present?
            }
          end
        }
      end
      def add_creator(name, attrs={})
        add_child_node(ng_xml.root, :name, name, (attrs).merge(role_code: 'cre', role_text: 'Creator', primary: true))
      end
      def add_contributor(name, attrs={})
        add_child_node(ng_xml.root, :name, name, attrs)
      end

      # Simple Subject Templates
      define_template(:simple_subject) do |xml, text, type|
        xml.subject { xml.send(type.to_sym, text) }
      end
      def add_subject(text, type)
        add_child_node(ng_xml.root, :simple_subject, text, type)
      end
      def add_topical_subject(text, *args);    add_subject(text, :topic);    end
      def add_geographic_subject(text, *args); add_subject(text, :geographic); end
      def add_temporal_subject(text, *args);   add_subject(text, :temporal);   end
      def add_occupation_subject(text, *args); add_subject(text, :occupation); end

      # Complex Subject Templates
      def add_name_subject(name, type)
        add_child_node(ng_xml.root.add_child('<subject/>'), :name, name, type: type)
      end
      def add_person_subject(name, *args);     add_name_subject(name, :personal);   end
      def add_corporate_subject(name, *args);  add_name_subject(name, :corporate);  end
      def add_occupation_subject(name, *args); add_name_subject(name, :occupation); end

      define_template :_language do |xml, code, text|
        xml.language {
          xml.languageTerm(:type => 'code') { xml.text(code) } if code.present?
          xml.languageTerm(:type => 'text') { xml.text(text) } if text.present?
        }
      end

      def add_language(value, opts={})
        begin
          term = LanguageTerm.find(value)
          add_child_node(ng_xml.root, :_language, term.code, term.text)
        rescue LanguageTerm::LookupError => e
          add_child_node(ng_xml.root, :_language, value, value)
        end
      end

      define_template :_terms_of_use do |xml, text|
        xml.accessCondition(:type => 'use and reproduction'){
          xml.text(text)
        }
      end

      def add_terms_of_use(value, opts={})
        add_child_node(ng_xml.root, :_terms_of_use, value)
      end

      define_template :_rights_statement do |xml, text|
        xml.accessCondition(:type => 'use and reproduction', :displayLabel => 'Rights Statement'){
          xml.text(text)
        }
      end

      def add_rights_statement(value, opts={})
        add_child_node(ng_xml.root, :_rights_statement, value)
      end

      def get_original_related_item
        node = find_by_terms(:original_related_item)
        if node.empty?
          node = ng_xml.root.add_child('<relatedItem type="original"/>')
        end
        Array(node).first
      end

      define_template :_original_physical_description do |xml, text|
        xml.physicalDescription{
          xml.extent{
            xml.text(text)
          }
        }
      end

      def add_physical_description(value, opts={})
        add_child_node(get_original_related_item, :_original_physical_description, value)
      end

      define_template :_other_identifier do |xml,text,type|
        type = ModsDocument::IDENTIFIER_TYPES.keys.first if type.empty?
        xml.identifier(:type => type) {
          xml.text(text)
        }
      end

      def add_other_identifier(content, attrs={})
        add_child_node(get_original_related_item, :_other_identifier, content, attrs)
      end

      define_template :media_type do |xml,mime_type|
        xml.physicalDescription {
          xml.internetMediaType mime_type
        }
      end

      def add_media_type(media_type_term, attrs={})
        add_child_node(ng_xml.root, :media_type, media_type_term)
      end

      define_template :_related_item do |xml, url, label|
        xml.relatedItem(:displayLabel => label) {
          xml.location { xml.url { xml.text(url) } } if url.present?
        } if label.present?
      end

      def add_related_item_url(url, label)
        add_child_node(ng_xml.root, :_related_item, url, label)
      end

      define_template :note do |xml,text,type='general'|
        xml.note(:type => type) {
          xml.text(text)
        }
      end

      def add_note(note_term, note_type_term)
        add_child_node(ng_xml.root, :note, note_term, note_type_term)
      end

      define_template :collection do |xml,collection_name|
        xml.relatedItem(:type => 'host') {
          xml.titleInfo {
            xml.title {
              xml.text(collection_name)
            }
          }
        }
      end

      define_template :place do |xml,place_term|
        xml.place {
          xml.placeTerm {
            xml.text(place_term)
          }
        }
      end

      def add_place_of_origin(place_term, *args)
        add_child_node(get_origin_info, :place, place_term)
      end

      define_template :url do |xml,url,attrs={}|
        xml.location {
          xml.url(attrs) {
            xml.text(url)
          }
        }
      end

      def add_location_url(url, attrs={})
        add_child_node(ng_xml.root, :url, url, attrs)
      end

      def add_permalink(url)
        add_location_url(url, { :access => 'object in context' })
      end

      define_template :_record_identifier do |xml,text,source|
        source = ModsDocument::IDENTIFIER_TYPES.keys.first unless source.present?
        xml.recordIdentifier(:source => source) {
          xml.text(text)
        }
      end

      def get_record_info
        node = find_by_terms(:record_info)
        if node.empty?
          node = ng_xml.root.add_child('<recordInfo/>')
        end
        Array(node).first
      end

      def add_bibliographic_id(content, source)
        add_child_node(get_record_info, :_record_identifier, content, source)
      end

      def add_record_identifier(content, source="Fedora4")
        add_child_node(get_record_info, :_record_identifier, content, source)
      end

      #TODO: Add series to MODS template
    end
  end

end
