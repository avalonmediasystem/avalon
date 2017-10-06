class SecurityService

  def rewrite_url(url, context)
    case Settings.streaming.server.to_sym
    when :aws
      configure_signer
      context[:protocol] ||= :stream_hls
      uri = Addressable::URI.parse(url)
      expiration = Settings.streaming.stream_token_ttl.minutes.from_now
      case context[:protocol]
      when :stream_flash
        # WARNING: UGLY FILENAME MUNGING AHEAD
        content_path = File.join(File.dirname(uri.path),File.basename(uri.path,File.extname(uri.path))).sub(%r(^/),'')
        content_prefix = File.extname(uri.path).sub(%r(^\.),'')
        result = Addressable::URI.join(Settings.streaming.rtmp_base,"cfx/st/#{content_prefix}:#{content_path}")
        result.query = Aws::CF::Signer.signed_params(content_path, expires: expiration).to_param
        result.to_s
      when :stream_hls
        Addressable::URI.join(Settings.streaming.http_base,uri.path).to_s
        #Aws::CF::Signer.sign_url(URI.join(Settings.streaming.http_base,uri.path).to_s, expires: expiration)
      else
        url
      end
    else
      session = context[:session] || { media_token: nil }
      token = StreamToken.find_or_create_session_token(session, context[:target])
      "#{url}?token=#{token}"
    end
  end

  def create_cookies(context)
    result = {}
    case Settings.streaming.server.to_sym
    when :aws
      configure_signer
      domain = Addressable::URI.parse(Settings.streaming.http_base).host
      cookie_domain = (context[:request_host].split(/\./) & domain.split(/\./)).join('.')
      resource = "http*://#{domain}/#{context[:target]}/*"
      Rails.logger.info "Creating signed policy for resource #{resource}"
      expiration = Settings.streaming.stream_token_ttl.minutes.from_now
      params = Aws::CF::Signer.signed_params(resource, expires: expiration, resource: resource)
      params.each_pair do |param,value|
        result["CloudFront-#{param}"] = {
          value: value,
          path: "/#{context[:target]}",
          domain: cookie_domain,
          expires: expiration
        }
      end
    end
    result
  end

  private

    def configure_signer
      require 'cloudfront-signer'
      unless Aws::CF::Signer.is_configured?
        Aws::CF::Signer.configure do |config|
          key = case Settings.streaming.signing_key
          when %r(^-----BEGIN)
            Settings.streaming.signing_key
          when %r(^s3://)
            FileLocator::S3File.new(Settings.streaming.signing_key).object.get.body.read
          when nil
            Rails.logger.warn('No CloudFront signing key configured')
          else
            File.read(Settings.streaming.signing_key)
          end
          config.key = key
          config.key_pair_id = Settings.streaming.signing_key_id
        end
      end
    end

end
