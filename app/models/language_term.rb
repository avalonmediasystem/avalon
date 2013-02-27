class LanguageTerm
	class LookupError < Exception; end

	Map = YAML.load(File.read(File.join(Rails.root, 'config/iso639-2.yml')))

	def self.find_by_code(value)
		key = "alpha#{value.length}".to_sym
		result = Map.find { |term| term[key] == value }
		raise LookupError, "Unknown language code: `#{value}'" if result.nil?
		self.new(result)
	end

	def self.find_by_text(value)
		v = value.downcase
		result = Map.find { |term| term[:en].collect(&:downcase).include? v }
		raise LookupError, "Unknown language: `#{value}'" if result.nil?
		self.new(result)
	end

	def initialize(term)
		@term = term
	end

	def code
		@term[:alpha3]
	end

	def text
		@term[:en].first
	end
end