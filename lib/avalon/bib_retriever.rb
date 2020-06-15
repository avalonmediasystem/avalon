# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

require 'marc'

module Avalon
  class BibRetriever
    XSLT_FILE = File.expand_path('../bib_retriever/MARC21slim2MODS3-5-avalon.xsl',__FILE__)
    attr_reader :config

    class << self
      def configured?(bib_id_type = 'default')
        begin
          self.for(bib_id_type)
        rescue ArgumentError
          false
        end
      end

      def instance(bib_id_type = 'default')
        self.for(bib_id_type)
      end

      def for(bib_id_type)
        config = configuration_for(bib_id_type)
        require config['retriever_class_require'] if config['retriever_class_require']
        config['retriever_class'].constantize.new config
      end

      protected :new, :allocate

      def configurations
        raise ArgumentError, "Missing/invalid bib retriever configuration" unless Settings.bib_retriever.present?
        Settings.bib_retriever
      end

      def configuration_for(bib_id_type)
        config = configurations[bib_id_type]
        config ||= configurations['default']
        raise ArgumentError, "Missing bib retriever configuration" unless config
        raise ArgumentError, "Invalid bib retriever configuration" unless valid_configuration?(config)
        config
      end

      def valid_configuration?(config)
        config.present? && config.respond_to?(:[]) && config['protocol'].present? && config['retriever_class'].present?
      end
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
