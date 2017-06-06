class AttachDerivativeJob < ActiveJob::Base
  queue_as :attach_derivative

  def perform(derivative_id)
    derivative = Derivative.find(derivative_id)
    changed = false
    unless derivative.absolute_location =~ %r{^s3://}
      location = derivative.absolute_location.split(/\//)[-4..-2].join('/')
      filename = File.basename(derivative.absolute_location)
      bucket = Aws::S3::Bucket.new(name: Settings.encoding.derivative_bucket)
      source_prefix = Pathname("pending/#{location}/")
      target_prefix = Pathname("#{derivative.master_file_id}/#{derivative.quality}/")

      source_objects = bucket.objects(prefix: source_prefix.to_s)
      source_objects.each do |source|
        target = target_prefix.join(Pathname(source.key).relative_path_from(source_prefix)).to_s.sub(%r{/segments/},'/hls/')
        destination = bucket.object(target)
        next if destination.exists?
        destination.copy_from(source, multipart_copy: source.size > 15.megabytes)
      end
      derivative.absolute_location = "s3://#{bucket.name}/#{target_prefix}#{filename}"
      changed = true
    end

    unless derivative.location_url =~ %r{^s3://} && derivative.hls_url =~ %r{^s3://}
      derivative.location_url = derivative.absolute_location
      uri = URI.parse(derivative.absolute_location)
      derivative.hls_url = uri.merge("hls/#{File.basename(uri.path,'.*')}.m3u8").to_s
      changed = true
    end
    derivative.save if changed
  end
end
