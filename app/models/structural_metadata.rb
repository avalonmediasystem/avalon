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

class StructuralMetadata < ActiveFedora::Datastream
  include ActiveFedora::Datastreams::NokogiriDatastreams

  def mimeType
    'text/xml'
  end

  def self.schema
    Nokogiri::XML::Schema(File.read('public/avalon_structure.xsd'))
  end

  delegate :xpath, to: :ng_xml

  def self.content_valid? content
    self.schema.validate(Nokogiri::XML(content))
  end

  def valid?
    self.class.schema.validate(self.ng_xml).empty?
  end

end
