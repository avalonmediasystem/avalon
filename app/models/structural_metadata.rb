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

class StructuralMetadata < ActiveFedora::File
  include SpeedyAF::IndexedContent
  include ActiveFedora::Datastreams::NokogiriDatastreams

  def mimeType
    'text/xml'
  end

  def self.schema
    Nokogiri::XML::Schema(File.read('public/avalon_structure.xsd'))
  end

  @sanitizer = Rails::Html::FullSanitizer.new

  def self.sanitize(s)
    @sanitizer.sanitize(s)
  end

  delegate :xpath, to: :ng_xml

  def self.content_valid?(content)
    self.schema.validate(Nokogiri::XML(content))
  end

  def valid?
    self.class.schema.validate(self.ng_xml).empty?
  end

  def section_title
    xpath('/Item/@label').text()
  end

  def as_json
    root_node = xpath('//Item')[0]
    root_node.present? ? node_xml_to_json(root_node) : {}
  end

  def self.from_json(js)
    document = Nokogiri::XML::Document.new
    root_node = Nokogiri::XML::Node.new('Item', document)
    root_node.set_attribute('label', sanitize(js[:label]))
    js[:items].each { |item| node_json_to_xml(item, root_node, document) }
    document.add_child(root_node)
    document.root.to_s
  end

  def self.node_json_to_xml(item, node, document)
    if item[:type].casecmp('div').zero?
      new_node = Nokogiri::XML::Node.new('Div', document)
      new_node.set_attribute('label', sanitize(item[:label]))
      item[:items].each { |i| node_json_to_xml(i, new_node, document) } if item[:items].present?
      node.add_child(new_node)
    elsif item[:type].casecmp('span').zero?
      new_node = Nokogiri::XML::Node.new('Span', document)
      new_node.set_attribute('label', sanitize(item[:label]))
      new_node.set_attribute('begin', item[:begin])
      new_node.set_attribute('end', item[:end])
      node.add_child(new_node)
    end
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
