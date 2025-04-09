# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

  class Iso6391 < LanguageTerm
    STORE = File.join(Rails.root, 'config/iso639-1.yml')
    VOCABULARY = 'http://id.loc.gov/vocabulary/iso639-1.tsv'

    class << self
      def convert_to_6392(term)
        raise LookupError, "Incorrect number of characters. Term must be a string of 2 alphabetic characters." unless /[a-zA-Z]{2}/.match?(term)
        lang_text = search(term).text
        # ISO 639-1 can have multiple languages defined for a single code:
        # 'es': "Spanish | Castilian".
        # ISO 639-2 does not follow the same convention, so we iterate through
        # any multi languages until we get a match from the ISO 639-2 standard.
        lang_text = lang_text.split('|').map(&:strip) if lang_text.include?('|')
        Array(lang_text).each do |text|
          begin
            @alpha3 = Iso6392.search(text)
            break
          rescue LookupError
            next
          end
        end

        raise LookupError, "Unknown language: `'#{value}" if @alpha3.nil?

        return @alpha3
      end

      def map
        @@map_alpha2 ||= self.load!
      end
    end
  end

  class Iso6392 < LanguageTerm
    STORE = File.join(Rails.root, 'config/iso639-2.yml')
    VOCABULARY = 'http://id.loc.gov/vocabulary/languages.tsv'

    class << self
      def map
        @@map ||= self.load!
      end
    end
  end

  class << self
    def find(term)
      case term.length
      when 2
        Iso6391.convert_to_6392(term)
      else
        Iso6392.search(term)
      end
    end
    alias_method :[], :find

    def search(value)
      result = self.map[value.downcase]
      result = self.map.select{ |k,v| v[:text]==value }.values.first if result.nil?
      raise LookupError, "Unknown language: `#{value}'" if result.nil?
      self.new(result)
    end

    def autocomplete(query, _id = nil)
      map = query.present? ? self.map.select{ |k,v| /#{query}/i.match(v[:text]) if v } : self.map
      map.to_a.uniq.map{ |e| {id: e[1][:code], display: e[1][:text] }}.sort{ |x,y| x[:display]<=>y[:display] }
    end

    def load!
      if File.exist?(store)
        YAML.load(File.read(store))
      else
        harvest!
      end
    end

    def harvest!
      language_map = {}
      doc = RestClient.get(vocabulary).split(/\n/).collect{ |l| l.split(/\t/) }
      doc.shift
      doc.each { |entry| language_map[entry[1].to_s] = { code: entry[1].to_s, text: entry[2].to_s, uri: entry[0].to_s } }
      begin
        File.open(store,'w') { |f| f.write(YAML.dump(language_map)) }
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

  def store
    self.class::STORE
  end

  def self.store
    self::STORE
  end

  def vocabulary
    self.class::VOCABULARY
  end

  def self.vocabulary
    self::VOCABULARY
  end
end
