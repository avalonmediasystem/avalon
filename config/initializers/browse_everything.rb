settings = if Settings.dropbox.google_drive
  { 'google_drive' => { client_id: Settings.dropbox.google_drive.client_id, client_secret: Settings.dropbox.google_drive.client_secret } }
elsif Settings.dropbox.path =~ %r{^s3://}
  obj = FileLocator::S3File.new(Settings.dropbox.path).object
  { 's3' => { name: 'AWS S3 Dropbox', bucket: obj.bucket_name, base: obj.key, response_type: :s3_uri } }
else
  { 'file_system' => { name: 'File Dropbox', home: Settings.dropbox.path } }
end
BrowseEverything.configure(settings)

# Patch BrowseEverything to get the correct download URL
# TODO: use newer version (>= 0.16.0)
BrowseEverything::Driver::GoogleDrive.class_eval do
  def link_for(id)
    file = drive.get_file(id, fields: "id, name, size, mimeType, videoMediaMetadata")
    auth_header = { 'Authorization' => "Bearer #{auth_client.access_token}" }
    extras = {
      auth_header: auth_header,
      expires: 3.hour.from_now,
      file_name: file.name,
      file_size: file.size.to_i
    }
    [download_url(id), extras]
  end

  def download_url(id)
    "https://www.googleapis.com/drive/v3/files/#{id}?alt=media"
  end
end
