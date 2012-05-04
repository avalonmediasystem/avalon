require 'hydra'
require "file_asset"
class VideoAsset < FileAsset
  include ActiveFedora::DatastreamCollections

  def initialize(attrs = {})
    super(attrs)
    add_relationship(:has_model, "info:fedora/afmodel:FileAsset")
  end

  has_datastream :name=>"content", :type=>ActiveFedora::Datastream, :controlGroup=>'R'
#  has_metadata :name => "descMetadata", :type => ActiveFedora::QualifiedDublinCoreDatastream

  # Set the url on the current object
  #
  # @param [String] new_url
  def set_url(new_url)
    if self.datastreams.has_key?("descMetadata")
      desc_metadata_ds = self.datastreams["descMetadata"]
      desc_metadata_ds.identifier = new_url
    end
  end

end

