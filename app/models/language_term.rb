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

class LanguageTerm
  class LookupError < Exception; end

  Store = File.join(Rails.root, 'config/iso639-2.yml')

  class << self
    def map
      @@map ||= self.load!
    end
    
    def find(value)
      result = self.map[value.downcase]
      result = self.map.select{ |k,v| v[:text]==value }.values.first if result.nil?
      raise LookupError, "Unknown language: `#{value}'" if result.nil?
      self.new(result)
    end
    alias_method :[], :find

    def autocomplete(query)
      map = query.present? ? self.map.select{ |k,v| /#{query}/i.match(v[:text]) if v } : self.map
      map.to_a.uniq.map{ |e| {id: e[1][:code], display: e[1][:text] }}.sort{ |x,y| x[:display]<=>y[:display] }
    end

    def load!
      if File.exist?(Store)
        YAML.load(File.read(Store))
      else
        harvest!
      end
    end
    
    def harvest!
      language_map = {}
      doc = RestClient.get('http://id.loc.gov/vocabulary/languages.tsv').split(/\n/).collect{ |l| l.split(/\t/) }
      doc.shift
      doc.each { |entry| language_map[entry[1].to_s] = { code: entry[1].to_s, text: entry[2].to_s, uri: entry[0].to_s } }
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
