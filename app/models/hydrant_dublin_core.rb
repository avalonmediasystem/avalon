class HydrantDublinCore < ActiveFedora::QualifiedDublinCoreDatastream
  set_terminology do |t|
    t.root(:path=>"dc", :xmlns=>"http://purl.org/dc/terms/")
    t.dc_type(:path => "type", :namespace_prefix=> "dcterms")
    t.dc_format(:path => "format", :namespace_prefix=> "dcterms")
  end
  
  # Call super to inject the rest back into the OM for the time being
  def initialize(digital_object, dsid)
    super(digital_object, dsid)
  end
end