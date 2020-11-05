ActiveEncode::Base.engine_adapter = Settings.encoding.engine_adapter.to_sym
case Settings.encoding.engine_adapter.to_sym
when :ffmpeg
  MasterFile.default_encoder_class = FfmpegEncode
when :matterhorn
  Rubyhorn.init
when :elastic_transcoder
  require 'aws-sdk-elastictranscoder'
  require 'avalon/elastic_transcoder'

  MasterFile.default_encoder_class = ElasticTranscoderEncode
  pipeline = Aws::ElasticTranscoder::Client.new.read_pipeline(id: Settings.encoding.pipeline)
  # Set environment variables to guard against reloads
  ENV['SETTINGS__ENCODING__MASTERFILE_BUCKET'] = Settings.encoding.masterfile_bucket = pipeline.pipeline.input_bucket
  ENV['SETTINGS__ENCODING__DERIVATIVE_BUCKET'] = Settings.encoding.derivative_bucket = pipeline.pipeline.output_bucket
  if Settings.dropbox.path.nil?
    ENV['SETTINGS__DROPBOX__PATH'] = Settings.dropbox.path = "s3://#{Settings.encoding.masterfile_bucket}/dropbox/"
  end
  if Settings.dropbox.upload_uri.nil?
    ENV['SETTINGS__DROPBOX__UPLOAD_URI'] = Settings.dropbox.upload_uri = "s3://#{Settings.encoding.masterfile_bucket}/dropbox/"
  end
end
