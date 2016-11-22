module FedoraMigrate
  class SimpleXmlDatastreamMover < FedoraMigrate::Mover

    attr_accessor :content

    def post_initialize
      @content = xml_from_content
    end

    def fields_to_copy
      []
    end
    
    def migrate
      fields_to_copy.each { |field| copy_field(field) }
      super
    end

    private
    def copy_field(source_field, target_field=nil, &block)
      target_field = source_field if target_field.nil?
      target.send("#{source_field}=".to_sym, present_or_nil(fetch_field(target_field.to_s), &block))
    end
    
    def fetch_field(name)
      @content.xpath("fields/#{name}").text
    end
    
    def present_or_nil(value)
      return nil unless value.present?
      block_given? ? yield(value) : value
    end

    def xml_from_content
      Nokogiri::XML(source.content)
    end
  end
end
