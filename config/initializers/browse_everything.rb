# Rails.application.config.after_initialize do
#   settings = {}
#   if Admin::ApplicationSetting.instance.dropbox.google_drive
#     settings['google_drive'] = {
#       client_id: Admin::ApplicationSetting.instance.dropbox.google_drive.client_id,
#       client_secret: Admin::ApplicationSetting.instance.dropbox.google_drive.client_secret
#     }
#   end
#   if Admin::ApplicationSetting.instance.dropbox.path =~ %r{^s3://}
#     obj = FileLocator::S3File.new(Admin::ApplicationSetting.instance.dropbox.path).object
#     settings['s3'] = { name: 'AWS S3 Dropbox', bucket: obj.bucket_name, base: obj.key, response_type: :s3_uri, region: obj.client.config.region }
#   else
#     settings['file_system'] = { name: 'File Dropbox', home: Admin::ApplicationSetting.instance.dropbox.path }
#   end
#   if Admin::ApplicationSetting.instance.dropbox.sharepoint
#     settings['sharepoint'] = {
#       client_id: Admin::ApplicationSetting.instance.dropbox.sharepoint.client_id,
#       client_secret: Admin::ApplicationSetting.instance.dropbox.sharepoint.client_secret,
#       tenant_id: Admin::ApplicationSetting.instance.dropbox.sharepoint.tenant_id,
#       scope: Admin::ApplicationSetting.instance.dropbox.sharepoint.scope,
#       redirect_uri: Admin::ApplicationSetting.instance.dropbox.sharepoint.redirect_uri
#     }
#   end
#   BrowseEverything.configure(settings)
# end
