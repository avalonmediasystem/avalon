settings = if Settings.dropbox.path =~ %r{^s3://}
  obj = FileLocator::S3File.new(Settings.dropbox.path).object
  { 's3' => { name: 'AWS S3 Dropbox', bucket: obj.bucket_name, base: obj.key, response_type: :s3_uri } }
else
  { 'file_system' => { name: 'File Dropbox', home: Settings.dropbox.path } }
end
BrowseEverything.configure(settings)
