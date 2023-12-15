# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

class SpeedyAF::Proxy::StructuralMetadata < SpeedyAF::Base
  delegate :xpath, to: :ng_xml

  def ng_xml
    @ng_xml ||= Nokogiri::XML::Document.parse(content).tap { |doc| StructuralMetadata.decorate_ng_xml doc }
  end

  def section_title
    xpath('/Item/@label').text
  end

  def as_json(_options = {})
    root_node = xpath('//Item')[0]
    root_node.present? ? node_xml_to_json(root_node) : {}
  end

  protected

    def node_xml_to_json(node)
      if node.name.casecmp("div").zero? || node.name.casecmp('item').zero?
        {
          type: 'div',
          label: node.attribute('label').value,
          items: node.children.reject(&:blank?).collect { |n| node_xml_to_json n }
        }
      elsif node.name.casecmp('span').zero?
        {
          type: 'span',
          label: node.attribute('label').value,
          begin: node.attribute('begin').present? ? node.attribute('begin').value : '0',
          end: node.attribute('end').present? ? node.attribute('end').value : '0'
        }
      end
    end
end
