module UploadFormHelper
  def direct_upload?
    Settings.encoding.engine_adapter.to_sym == :elastic_transcoder
  end

  def upload_form_classes
    result = %w(uploader-form form-horizontal step)
    result << 'directupload' if direct_upload?
    result.join(' ')
  end

  def upload_form_data
    if direct_upload?
      bucket = Aws::S3::Bucket.new(name: Settings.encoding.masterfile_bucket)
      direct_post = bucket.presigned_post(key: "uploads/#{SecureRandom.uuid}/${filename}", success_action_status: '201')
      {
        'form-data' => (direct_post.fields),
        'url' => direct_post.url,
        'host' => URI.parse(direct_post.url).host
      }
    else
      {}
    end
  end
end
