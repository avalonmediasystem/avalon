require 'hydra'
require "file_asset"

class VideoAsset < FileAsset
  include ActiveFedora::DatastreamCollections
  attr_reader :status
  
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
  
  def source=(source)
    descMetadata.source = source
  end
  
  def source
    descMetadata.source
  end

  protected
  def refresh_status
    workflow_id = source
    matterhorn_response = Rubyhorn.client.instance_xml(workflow_id)
    workflow_status = matterhorn_response.workflow.state[0]
 
    puts "<< Matterhorn status is #{workflow_status} >>"
    video_asset.description = workflow_status
    video_asset.save
  end

end

