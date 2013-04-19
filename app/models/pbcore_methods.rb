# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

module PbcoreMethods

  # Module for inserting different types of PBcore xml nodes into
  # an existing PBcore document

  module ClassMethods

#     def publisher_template(opts={})
#       builder = Nokogiri::XML::Builder.new do |xml|
#         xml.pbcorePublisher {
#           xml.publisher
#           xml.publisherRole(:source=>"PBCore publisherRole")
#         }
#       end
#       return builder.doc.root
#     end
# 
#     def contributor_template(opts={})
#       builder = Nokogiri::XML::Builder.new do |xml|
#         xml.pbcoreContributor {
#           xml.contributor
#           xml.contributorRole(:source=>"MARC relator terms")
#         }
#       end
#       return builder.doc.root
#     end

  def relation_template(opts={})
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.pbcoreRelation {
        xml.pbcoreRelationType
        xml.pbcoreRelationIdentifier(:source=>"Avalon Media System")
      }
    end
    return builder.doc.root
  end

    def previous_template(opts={})
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.instantiationRelation {
          xml.instantiationRelationType(:annotation=>"One of a multi-part instantiation") {
            xml.text "Follows in Sequence"
          }
          xml.instantiationRelationIdentifier(:source=>"Avalon Media System")
        }
      end
      return builder.doc.root
    end

    def next_template(opts={})
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.instantiationRelation {
          xml.instantiationRelationType(:annotation=>"One of a multi-part instantiation") {
            xml.text "Precedes in Sequence"
          }
          xml.instantiationRelationIdentifier(:source=>"Avalon Media System")
        }
      end
      return builder.doc.root
    end

 end

  def self.included(klass)
    klass.extend(ClassMethods)
  end

  def insert_node(type, opts={})

    unless self.class.respond_to?("#{type}_template".to_sym)
      raise "No XML template is defined for a PBcore node of type #{type}."
    end

    node = self.class.send("#{type}_template".to_sym)
    nodeset = self.find_by_terms(type.to_sym)

    unless nodeset.nil?
      if nodeset.empty?
        if opts[:root]
          self.find_by_terms(opts[:root].to_sym).first.add_child(node)
        else
          self.ng_xml.root.add_child(node)
        end
        index = 0
      else
        nodeset.after(node)
        index = nodeset.length
      end
      self.dirty = true
    end

    return node, index

  end

  def remove_node(type, index)
    if type == "education" or type == "television"
      self.find_by_terms(type.to_sym).slice(index.to_i).parent.remove
    else
      self.find_by_terms(type.to_sym).slice(index.to_i).remove
    end
    self.dirty = true
  end

end
