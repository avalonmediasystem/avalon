Rails.application.config.after_initialize do
  if Admin::ApplicationSetting.instance.dropbox.path =~ %r{^s3://}
    Avalon::Batch::Manifest.concrete_class = Avalon::Batch::S3Manifest
  end
end
