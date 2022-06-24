# Initializer commented out due to entire controller being overridden
# TODO: Remove override and reinstate this intitializer

BrowseEverythingController.before_action do
  if params[:context]
    collection = Admin::Collection.find(params[:context])
    if browser.providers['file_system'].present?
      browser.providers['file_system'].config[:home] = collection.dropbox_absolute_path
    end
    if browser.providers['s3'].present?
      browser.providers['s3'].config[:base] = FileLocator::S3File.new(collection.dropbox_absolute_path).key
    end
  end
end
