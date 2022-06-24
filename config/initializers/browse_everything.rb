Rails.application.config.to_prepare do
  settings = if Settings.dropbox.google_drive
    { 'google_drive' => { client_id: Settings.dropbox.google_drive.client_id,
                          client_secret: Settings.dropbox.google_drive.client_secret
                        }
    }
  elsif Settings.dropbox.path =~ %r{^s3://}
    obj = FileLocator::S3File.new(Settings.dropbox.path).object
    { 's3' => { name: 'AWS S3 Dropbox', bucket: obj.bucket_name, base: obj.key, response_type: :s3_uri, region: obj.client.config.region } }
  else
    { 'file_system' => { name: 'File Dropbox', home: Settings.dropbox.path } }
  end
  BrowseEverything.configure(settings)
end
