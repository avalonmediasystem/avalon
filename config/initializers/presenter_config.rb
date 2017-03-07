module StructuralMetadataPresenterBehavior
  def ng_xml
    @ng_xml ||= Nokogiri::XML(content)
  end

  def xpath(*args)
    ng_xml.xpath(*args)
  end
end

SpeedyAF::SolrPresenter.tap do |sp|
  sp.config MasterFile, defaults: { permalink: nil }, mixins: [MasterFileBehavior, Rails.application.routes.url_helpers]
  sp.config Derivative, mixins: [DerivativeBehavior]
  sp.config StructuralMetadata, mixins: [StructuralMetadataPresenterBehavior]
end
