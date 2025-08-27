Rails.application.config.to_prepare do
  ActiveEncode::Base.engine_adapter = Settings.encoding.engine_adapter.to_sym
  case Settings.encoding.engine_adapter.to_sym
  when :ffmpeg
    MasterFile.default_encoder_class = FfmpegEncode
    ActiveEncode::EngineAdapters::FfmpegAdapter.completeness_threshold = 95
  when :matterhorn
    Rubyhorn.init
  when :elastic_transcoder
    require 'aws-sdk-elastictranscoder'
    require 'avalon/elastic_transcoder_encode'

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
  when :media_convert
    require 'avalon/media_convert_encode'

    MasterFile.default_encoder_class = MediaConvertEncode

    # Create presets if they don't exist
    media_convert_client = Aws::MediaConvert::Client.new
    existing_presets = media_convert_client.list_presets(category: "avalon", list_by: "NAME").presets.map(&:name)
    Dir[Settings.encoding.presets_path + "/*.json"].each do |file|
      json = JSON.parse(File.read(file)).deep_transform_keys! {|k| k.underscore.to_sym }
      next if existing_presets.include?(json[:name])

      media_convert_client.create_preset(json)
    rescue Exception => e
      Rails.logger.error "Error reading preset #{file}: #{e.message}"
      next
    end

    if Settings.dropbox.path.nil?
      ENV['SETTINGS__DROPBOX__PATH'] = Settings.dropbox.path = "s3://#{Settings.encoding.masterfile_bucket}/dropbox/"
    end
    if Settings.dropbox.upload_uri.nil?
      ENV['SETTINGS__DROPBOX__UPLOAD_URI'] = Settings.dropbox.upload_uri = "s3://#{Settings.encoding.masterfile_bucket}/dropbox/"
    end
  end
end
