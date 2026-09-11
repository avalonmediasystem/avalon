Rails.application.config.to_prepare do
  Avalon::Batch::Manifest.concrete_class = lambda do
    if Admin::ApplicationSetting.instance.dropbox.path.match?(%r{^s3://})
      Avalon::Batch::S3Manifest
    else
      Avalon::Batch::FileManifest
    end
  end
end
