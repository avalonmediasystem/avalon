require 'hydra'
require "file_asset"

class VideoAsset < FileAsset
  include ActiveFedora::DatastreamCollections
  
  def initialize(attrs = {})
    super(attrs)
    add_relationship(:has_model, "info:fedora/afmodel:FileAsset")
    refresh_status
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
	puts "<< #{status} >>"
	descMetadata.description
  end
  
  def source=(source)
    puts "<< SOURCE : #{source} >>"
    descMetadata.source = source
  end
  
  def source
    descMetadata.source
  end

  # A hacky way to handle the description for now. This should probably be refactored
  # to stop pulling if the status is stopped or completed
  def status
    unless source.nil? or source.empty?
      refresh_status
    end
  end
  
  protected
  def refresh_status
    matterhorn_response = Rubyhorn.client.instance_xml(source[0])
    status = matterhorn_response.workflow.state[0]
 
    descMetadata.description = case status
      when "INSTANTIATED"
        "Preparing file for conversion"
      when "RUNNING"
        "Creating derivatives"
      when "SUCCEEDED"
        "Processing is complete"
      when "FAILED"
        "File(s) could not be processed"
      when "STOPPED"
        "Processing has been stopped"
      else
        "No file(s) uploaded"
      end
    save
  end

end

