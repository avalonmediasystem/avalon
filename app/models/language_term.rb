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

class LanguageTerm
	class LookupError < Exception; end

	Store = File.join(Rails.root, 'config/iso639-2.yml')

	class << self
		def map
			@@map ||= self.load!
		end

		def find(value)
			result = self.map[value.downcase]
			raise LookupError, "Unknown language: `#{value}'" if result.nil?
			self.new(result)
		end
		alias_method :[], :find

	  def load!
	  	if File.exists?(Store)
	  		YAML.load(File.read(Store))
	  	else
	  		harvest!
	  	end
	  end

		def harvest!
			language_map = {}

			doc = Nokogiri::XML(RestClient.get('http://www.loc.gov/standards/codelists/languages.xml'))

			doc.xpath('//xmlns:name').each do |node|
				code = node.xpath('ancestor-or-self::xmlns:language/xmlns:code[count(@status) = 0 or @status!="obsolete"]').text
				auth_name = node.xpath('ancestor-or-self::*[xmlns:name[@authorized="yes"]]/xmlns:name').text
				auth_name = node.xpath('ancestor-or-self::xmlns:language/xmlns:name').text if auth_name.blank?
				language_map[node.text.downcase] = { :code => code, :text => auth_name } unless code.blank? or auth_name.blank?
			end

			doc.xpath('//xmlns:code[count(@status) = 0 or @status!="obsolete"]').each do |node|
				code = node.text
				auth_name = node.parent.xpath('xmlns:name').text
				language_map[node.text.downcase] = { :code => code, :text => auth_name } unless code.blank? or auth_name.blank?
			end

			alpha2_map = RestClient.get('http://www.loc.gov/standards/iso639-2/ISO-639-2_utf-8.txt').split(/\n/).collect { |l| l.split(/\|/) }
			alpha2_map.each { |entry| language_map[entry[2]] = language_map[entry[0]] unless entry[2].blank? }

			begin
				File.open(Store,'w') { |f| f.write(YAML.dump(language_map)) }
			rescue
				# Don't care if we can't cache it
			end

			language_map
		end
	end

	def initialize(term)
		@term = term
	end

	def code
		@term[:code]
	end

	def text
		@term[:text]
	end
end
