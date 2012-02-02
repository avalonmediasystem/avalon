module VideoAssetsHelper
  # Generate the appropriate url for posting uploads to
  # Uses the +container_id+ method to figure out what container uploads should go into
  def video_upload_url
    upload_url = "/assets/#{container_id}/video_assets"
  end
end
