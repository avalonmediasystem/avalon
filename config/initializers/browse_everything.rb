Rails.application.config.to_prepare do
  settings = {}
  if Settings.dropbox.google_drive
    settings['google_drive'] = { client_id: Settings.dropbox.google_drive.client_id,
                                 client_secret: Settings.dropbox.google_drive.client_secret
                               }
  end
  if Settings.dropbox.path =~ %r{^s3://}
    obj = FileLocator::S3File.new(Settings.dropbox.path).object
    settings['s3'] = { name: 'AWS S3 Dropbox', bucket: obj.bucket_name, base: obj.key, response_type: :s3_uri, region: obj.client.config.region }
  else
    settings['file_system'] = { name: 'File Dropbox', home: Settings.dropbox.path }
  end
  BrowseEverything.configure(settings)
end
