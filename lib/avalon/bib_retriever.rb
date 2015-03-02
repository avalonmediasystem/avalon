# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

module Avalon
  class BibRetriever
    XSLT_FILE = File.expand_path('../bib_retriever/MARC21slim2MODS3-5-avalon.xsl',__FILE__)
    attr_reader :config
    
    class << self
      def configured?
        begin
          instance.present?
        rescue ArgumentError
          false
        end
      end
      
      def instance
        config = Avalon::Configuration.lookup('bib_retriever')
        unless config.respond_to?(:[]) and config['protocol'].present?
          raise ArgumentError, "Missing/invalid bib retriever configuration" 
        end
        
        case config['protocol'].downcase
        when 'sru', /^yaz/
          require 'avalon/bib_retriever/sru'
          Avalon::BibRetriever::SRU.new config
        when /^z(oom|39)/
          require 'avalon/bib_retriever/zoom'
          Avalon::BibRetriever::Zoom.new config
        else
          raise ArgumentError, "Unknown bib retriever protocol: #{config['protocol']}"
        end
      end
      
      protected :new, :allocate
    end
    
    def initialize config
      @config = config
    end

    def marcxml2mods(marcxml)
      xsl ||= Dir.chdir(File.dirname(XSLT_FILE)) { Nokogiri::XSLT.parse(File.read(XSLT_FILE)) }
      doc = Nokogiri::XML(marcxml)
      mods = xsl.transform(doc)
      mods.to_s
    end
    
    def marc2mods(marc)
      record = MARC::Reader.decode marc
      marcxml = record.to_xml.to_s
      marcxml2mods(marcxml)
    end
  end
end
