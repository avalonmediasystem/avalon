class SecurityHandler
  class << self
    def secure_url(url, context={})
      @shim&.call(url, context) || url
    end

    def secure_cookies(context={})
      @cookie_shim&.call(context) || {}
    end

    def rewrite_url(&block)
      @shim = block
    end

    def create_cookies(&block)
      @cookie_shim = block
    end
  end
end
