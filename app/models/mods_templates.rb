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

		  def add_title(title, attrs={}, defaults={})
		  	add_child_node(ng_xml.root, :title_info, title, defaults.merge(attrs))
		  end
		  def add_main_title(title, attrs={}); 				add_title(title, attrs, primary: true);      end
		  def add_alternative_title(title, attrs={}); add_title(title, attrs, type: :alternative); end
		  def add_translated_title(title, attrs={});  add_title(title, attrs, type: :translated);  end
		  def add_uniform_title(title, attrs={});     add_title(title, attrs, type: :uniform);     end

		  define_template :origin_info_child do |xml, type, value, attributes={}|
		  	xml.send(type, attributes) { xml.text value }
		  end

		  def get_origin_info
		  	node = find_by_terms(:origin_info)
		  	if node.empty?
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
		  	logger.debug([name, opts].inspect)
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
		    logger.debug(xml.parent.to_xml)
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
	  		term = LanguageTerm.find(value)
	  		add_child_node(ng_xml.root, :_language, term.code, term.text)
	  	end

		  define_template :media_type do |xml,mime_type|
		    xml.physicalDescription {
		      xml.internetMediaType mime_type
		    }
		  end

		  define_template :note do |xml,text,type='general'|
		  	xml.note(:type => type) {
		  		xml.text(text)
		  	}
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

		end
	end

end
