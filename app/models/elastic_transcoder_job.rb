class ElasticTranscoderJob < ActiveEncode::Base
  before_create :set_up_options
  before_create :copy_to_input_bucket

  JOB_STATES = {
    "Submitted" => :running, "Progressing" => :running, "Canceled" => :cancelled,
    "Error" => :failed, "Complete" => :completed
  }

  JOB_COMPLETION = {
    "Submitted" => 10, "Progressing" => 50, "Complete" => 100
  }

  def self.find(id)
    job = Aws::ElasticTranscoder::Client.new.read_job(id: id)&.job
    return nil if job.nil?
    encode = self.new(job.input, {})
    encode.populate(job)
  end

  def set_up_options
    file_name = File.basename(Addressable::URI.parse(input).path,'.*').gsub(URI::UNSAFE,'_')
    outputs = {
      fullaudio: {
        hls_medium: { key: "quality-medium/hls/#{file_name}", preset_id: find_or_create_preset('ts',:audio,:medium).id, segment_duration: '2' },
        hls_high: { key: "quality-high/hls/#{file_name}", preset_id: find_or_create_preset('ts',:audio,:high).id, segment_duration: '2' },
        aac_medium: { key: "quality-medium/#{file_name}.mp4", preset_id: find_or_create_preset('mp4',:audio,:medium).id },
        aac_high: { key: "quality-high/#{file_name}.mp4", preset_id: find_or_create_preset('mp4',:audio,:high).id }
      },
      avalon: {
        hls_low: { key: "quality-low/hls/#{file_name}", preset_id: find_or_create_preset('ts',:video,:low).id, segment_duration: '2' },
        hls_medium: { key: "quality-medium/hls/#{file_name}", preset_id: find_or_create_preset('ts',:video,:medium).id, segment_duration: '2' },
        hls_high: { key: "quality-high/hls/#{file_name}", preset_id: find_or_create_preset('ts',:video,:high).id, segment_duration: '2' },
        mp4_low: { key: "quality-low/#{file_name}.mp4", preset_id: find_or_create_preset('mp4',:video,:low).id },
        mp4_medium: { key: "quality-medium/#{file_name}.mp4", preset_id: find_or_create_preset('mp4',:video,:medium).id },
        mp4_high: { key: "quality-high/#{file_name}.mp4", preset_id: find_or_create_preset('mp4',:video,:high).id }
      }
    }

    self.options[:output_key_prefix] ||= "#{SecureRandom.uuid}/"
    self.options.merge!({
      pipeline_id: Settings.encoding.pipeline,
      outputs: outputs[self.options[:preset].to_sym].values
    })
  end

  def copy_to_input_bucket
    case Addressable::URI.parse(input).scheme
    when nil,'file'
      upload_to_s3
    when 's3'
      check_s3_bucket
    end
  end

  def populate(job)
    self.id = job.id
    self.state = JOB_STATES[job.status]
    self.current_operations = []
    self.percent_complete = (job.outputs.select { |o| o.status == 'Complete' }.length.to_f / job.outputs.length.to_f) * 100
    self.created_at = convert_time(job.timing["submit_time_millis"])
    self.updated_at = convert_time(job.timing["start_time_millis"])
    self.finished_at = convert_time(job.timing["finish_time_millis"])

    self.output = convert_output(job)
    self.errors = job.outputs.select { |o| o.status == "Error" }.collect(&:status_detail).compact
    self.tech_metadata = convert_tech_metadata(job.input.detected_properties)
    self
  end

  def remove_output!(id)
    track = output.find { |o| o[:id] == id }
    raise "Unknown track: `#{id}'" if track.nil?
    s3_object = FileLocator::S3File.new(track[:url]).object
    if s3_object.key =~ /\.m3u8$/
      delete_segments(s3_object)
    else
      s3_object.delete
    end
  end

  def delete_segments(obj)
    raise "Invalid segmented video object" unless obj.key =~ %r(quality-.+/.+\.m3u8$)
    bucket = obj.bucket
    prefix = obj.key.sub(/\.m3u8$/,'')
    next_token = nil
    loop do
      response = s3client.list_objects_v2(bucket: obj.bucket_name, prefix: prefix, continuation_token: next_token)
      response.contents.collect(&:key).each { |key| bucket.object(key).delete }
      next_token = response.continuation_token
      break if next_token.nil?
    end
  end

  private

    def etclient
      Aws::ElasticTranscoder::Client.new
    end

    def s3client
      Aws::S3::Client.new
    end

    def check_s3_bucket
      logger.info("Checking `#{input}'")
      s3_object = FileLocator::S3File.new(input).object
      if s3_object.bucket_name == source_bucket
        logger.info("Already in bucket `#{source_bucket}'")
        self.input = s3_object.key
      else
        self.input = File.join(SecureRandom.uuid,s3_object.key)
        logger.info("Copying to `#{source_bucket}/#{input}'")
        target = Aws::S3::Object.new(bucket_name: source_bucket, key: self.input)
        target.copy_from(s3_object, multipart_copy: s3_object.size > 15.megabytes)
      end
    end

    def upload_to_s3
      original_input = input
      bucket = Aws::S3::Resource.new(client: s3client).bucket(source_bucket)
      filename = FileLocator.new(input).location
      self.input = File.join(SecureRandom.uuid,File.basename(filename))
      logger.info("Copying `#{original_input}' to `#{source_bucket}/#{input}'")
      obj = bucket.object(input)
      obj.upload_file filename
    end

    def source_bucket
      Settings.encoding.masterfile_bucket
    end

    def find_preset(container, format, quality)
      container_description = container == 'ts' ? 'hls' : container
      result = nil
      next_token = nil
      loop do
        resp = etclient.list_presets page_token: next_token
        result = resp.presets.find { |p| p.name == "avalon-#{format}-#{quality}-#{container_description}" }
        next_token = resp.next_page_token
        break if result.present? || next_token.nil?
      end
      result
    end

    def read_preset(id)
      etclient.read_preset(id: id).preset
    end

    def create_preset(container, format, quality)
      etclient.create_preset(preset_settings(container, format, quality)).preset
    end

    def find_or_create_preset(container, format, quality)
      find_preset(container, format, quality) || create_preset(container, format, quality)
    end

    def preset_settings(container, format, quality)
      templates = YAML.load(File.read(File.join(Rails.root,'config','encoding_presets.yml')))
      template = templates[:templates][format.to_sym].deep_dup.deep_merge(templates[:settings][format.to_sym][quality.to_sym])
      container_description = container == 'ts' ? 'hls' : container
      template.merge!({
        name: "avalon-#{format}-#{quality}-#{container_description}",
        description: "Avalon Media System: #{format}/#{quality}/#{container_description}",
        container: container
      })
    end

    def convert_time(time_millis)
      return nil if time_millis.nil?
      Time.at(time_millis / 1000).iso8601
    end

    def convert_bitrate(rate)
      return nil if rate.nil?
      (rate.to_f * 1024).to_s
    end

    def convert_output(job)
      pipeline = etclient.read_pipeline(id: job.pipeline_id).pipeline
      job.outputs.collect do |output|
        preset = read_preset(output.preset_id)
        extension = preset.container == 'ts' ? '.m3u8' : ''
        convert_tech_metadata(output,preset).merge({
          managed: false,
          id: output.id,
          label: output.key.split("/", 2).first,
          url: "s3://#{pipeline.output_bucket}/#{job.output_key_prefix}#{output.key}#{extension}"
        })
      end
    end

    def convert_tech_metadata(props, preset=nil)
      return {} if props.nil? || props.empty?
      metadata_fields = {
        file_size: { key: :file_size, method: :itself },
        duration_millis: { key: :duration, method: :to_s },
        frame_rate: { key: :video_framerate, method: :itself },
        segment_duration: { key: :segment_duration, method: :itself },
        width: { key: :width, method: :itself },
        height: { key: :height, method: :itself }
      }

      metadata = {}
      props.each_pair do |key, value|
        next if value.nil?
        conversion = metadata_fields[key.to_sym]
        next if conversion.nil?
        metadata[conversion[:key]] = value.send(conversion[:method])
      end

      unless preset.nil?
        audio = preset.audio
        video = preset.video
        metadata.merge!({
          audio_codec: audio&.codec,
          audio_channels: audio&.channels,
          audio_bitrate: convert_bitrate(audio&.bit_rate),
          video_codec: video&.codec,
          video_bitrate: convert_bitrate(video&.bit_rate)
        })
      end

      metadata
    end
end
