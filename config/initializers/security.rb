SecurityHandler.rewrite_url do |url, context|
  session = context[:session] || { media_token: nil }
  token = StreamToken.find_or_create_session_token(session, context[:target])
  "#{url}?token=#{token}"
end
