Rails.application.config.to_prepare do
  SpeedyAF::Base.tap do |sp|
    sp.config MasterFile do
      self.defaults = { permalink: nil }
      include MasterFileBehavior
      include Rails.application.routes.url_helpers
    end

    sp.config Derivative do
      include DerivativeBehavior
    end

    sp.config StructuralMetadata do
      def ng_xml
	@ng_xml ||= Nokogiri::XML(content)
      end

      def xpath(*args)
	ng_xml.xpath(*args)
      end
    end
  end
end
