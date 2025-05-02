# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

require 'zip'

module Avalon
  class DocxFile
    def initialize(io)
      zip_file = Zip::File.open_buffer(io)
      document = zip_file.glob('word/document*.xml').first
      raise Errno::ENOENT if document.nil?
      document_xml = document.get_input_stream.read
      @doc = Nokogiri::XML(document_xml)
    end

    def unformatted_text
      @doc.xpath('//w:document//w:body/w:p').map(&:content).join("\n")
    end
  end
end
