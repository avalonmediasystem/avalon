class AttachDerivativeJob < ActiveJob::Base
  queue_as :attach_derivative

  def perform(derivative_id)
    derivative = Derivative.find(derivative_id)
    location = derivative.derivativeFile.split(/\//)[-4..-2].join('/')
    filename = File.basename(derivative.derivativeFile)
    client = Aws::S3::Client.new
    bucket = Aws::S3::Bucket.new(name: Settings.encoding.derivative_bucket)
    source_prefix = Pathname("pending/#{location}/")
    target_prefix = Pathname("#{derivative.master_file_id}/#{derivative.quality}/")

    source_objects = bucket.objects(prefix: source_prefix.to_s)
    source_objects.each do |source|
      target = target_prefix.join(Pathname(source.key).relative_path_from(source_prefix)).to_s.sub(%r{/segments/},'/hls/')

      client.copy_object({
        copy_source: "#{source.bucket_name}/#{source.key}",
        bucket: bucket.name,
        key: target
      })
    end

    derivative.derivativeFile = "s3://#{bucket.name}/#{target_prefix}#{filename}"
    derivative.set_streaming_locations!
    derivative.save
  end
end
