module ModsTemplates
	extend ActiveSupport::Concern

	included do
		class_eval do
		  def self.delegate_to_template(xml, template, *args)
		    if xml.is_a?(Nokogiri::XML::Builder)
		      xml = xml.doc.root
		    elsif xml.is_a?(Nokogiri::XML::Document)
		      xml = xml.root
		    end
		    xml.add_child(template_registry.instantiate(template, *args))
		  end

		  # Title Templates
		  define_template :title_info do |xml, title, opts|
		    attrs = opts[:type].present? ? { :type => opts[:type].to_s } : {}
		    xml.titleInfo(attrs) {
		      xml.title(title)
		      xml.subTitle(opts[:subtitle]) if opts[:subtitle].present?
		    }
		  end
		  define_template(:title)             { |xml, title, attrs| delegate_to_template(xml, :title_info, attrs.merge({ type: :primary })     }
		  define_template(:alternative_title) { |xml, title, attrs| delegate_to_template(xml, :title_info, attrs.merge({ type: :alternative }) }
		  define_template(:translated_title)  { |xml, title, attrs| delegate_to_template(xml, :title_info, attrs.merge({ type: :translated })  }
		  define_template(:uniform_title)     { |xml, title, attrs| delegate_to_template(xml, :title_info, attrs.merge({ type: :uniform })     }

		  # Name Templates
		  define_template :name do |xml, name, attributes|
		  	opts = { type: 'personal', role_code: 'cre', role_text: 'Creator', primary: false }.merge(attributes)
		  	attrs = { :type => type }
		  	attrs['primary']="true" if opts[:primary]
		    xml.name(attrs) {
		      xml.namePart(name)
		      if (opts[:role_code].present? or opts[:role_text].present?)
		        xml.role {
		          xml.roleTerm(:authority => 'marcrelator', :type => 'code') { xml.text(role_code) } if opts[:role_code].present?
		          xml.roleTerm(:authority => 'marcrelator', :type => 'text') { xml.text(role_text) } if opts[:role_text].present?
		        }
		      end
		    }
		  end
		  define_template(:personal_name)  { |xml, name, attrs| delegate_to_template(xml, :name, name, attrs.merge({ type: :personal }) }
		  define_template(:corporate_name) { |xml, name, attrs| delegate_to_template(xml, :name, name, attrs.merge({ type: :corporate }) }
		  define_template(:family_name)    { |xml, name, attrs| delegate_to_template(xml, :name, name, attrs.merge({ type: :family }) }

		  # Simple Subject Templates
		  define_template(:simple_subject)     { |xml, text, type| xml.subject { xml.send(type.to_sym, text) } }
		  define_template(:topical_subject)    { |xml, text| delegate_to_template(xml, :simple_subject, text, :topic) 		 }
		  define_template(:geographic_subject) { |xml, text| delegate_to_template(xml, :simple_subject, text, :geographic) }
		  define_template(:temporal_subject)   { |xml, text| delegate_to_template(xml, :simple_subject, text, :temporal)   }
		  define_template(:occupation_subject) { |xml, text| delegate_to_template(xml, :simple_subject, text, :occupation) }

		  # Complex Subject Templates
		  define_template(:name_subject)      { |xml, name, type| xml.subject; delegate_to_template(xml.doc.root.children.first, :name, type, name) }
		  define_template(:person_subject)    { |xml, name| delegate_to_template(xml, :name_subject, name, :personal)  }
		  define_template(:corporate_subject) { |xml, name| delegate_to_template(xml, :name_subject, name, :corporate) }
		  define_template(:family_subject)    { |xml, name| delegate_to_template(xml, :name_subject, name, :family)    }

		  define_template :language do |xml, code, text|
		    xml.language {
		      xml.languageTerm(:type => 'code') { xml.text(code) } if code.present?
		      xml.languageTerm(:type => 'text') { xml.text(text) } if text.present?
		    }
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
		end
	end

end