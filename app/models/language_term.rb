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