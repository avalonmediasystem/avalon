require 'hydra'
require "file_asset"

class VideoAsset < FileAsset
  include ActiveFedora::DatastreamCollections
  
  def initialize(attrs = {})
    super(attrs)
    add_relationship(:has_model, "info:fedora/afmodel:FileAsset")
  end

  has_datastream :name => "content", :type => ActiveFedora::Datastream, 
    :controlGroup => 'R'

  # Set the url on the current object
  #
  # @param [String] new_url
  def url=(url)
    descMetadata.identifier = url
  end

  # Sets the description on the current object
  def description=(description)
	descMetadata.description = description
  end

  def description
	descMetadata.description
  end
end

