module PbcoreMethods

  # Module for inserting different types of PBcore xml nodes into
  # an existing PBcore document

  module ClassMethods

    def publisher_template(opts={})
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.pbcorePublisher {
          xml.publisher
          xml.publisherRole(:source=>"PBCore publisherRole")
        }
      end
      return builder.doc.root
    end

    def contributor_template(opts={})
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.pbcoreContributor {
          xml.contributor
          xml.contributorRole(:source=>"MARC relator terms")
        }
      end
      return builder.doc.root
    end

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

  def scrub_hash(input = {}, datastream = :descMetadata)
    logger.debug "<< SCRUB HASH >>"
    logger.debug "<< Before => #{input.inspect} >>"
    
    input.each do |k, v|
     input.remove(k) unless self.datastream.class.terminology.has_term?(k)
    end
    
    logger.debug "<< After => #{input.inspect} >>"
    input
  end
   
  def update_document(values = {})
    values.each do |element, value|  
      # See if the node exists. If not inject a new one then set the new value
      #
      # node.exists?(element.to_sym)
      
    end
    
    # Next iterate over each remaining element. If there are more elements than in the
    # array then remove the extra values from the document
    
    # Commit the new value to the document
    
    # Save the document
  end
end
