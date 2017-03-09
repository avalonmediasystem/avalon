module DerivativeBehavior
  def absolute_location
    derivativeFile
  end

  def tokenized_url(token, mobile = false)
    uri = streaming_url(mobile)
    "#{uri}?token=#{token}".html_safe
  end

  def streaming_url(is_mobile = false)
    is_mobile ? hls_url : location_url
  end

  def format
    if video_codec.present?
      'video'
    elsif audio_codec.present?
      'audio'
    else
      'other'
    end
  end
end
