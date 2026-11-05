if Settings.dropbox.path =~ %r{^s3://}
  Avalon::Batch::Manifest.concrete_class = Avalon::Batch::S3Manifest
end
