if Settings.minio
  require "aws-sdk-s3"

  Aws.config.update(
      endpoint: Settings.minio.endpoint,
      access_key_id: Settings.minio.access,
      secret_access_key: Settings.minio.secret,
      force_path_style: true,
      region: ENV["AWS_REGION"]
    )
end
