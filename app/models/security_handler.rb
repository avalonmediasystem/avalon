class SecurityHandler
  class << self
    def secure_url(url, context={})
      return @shim.call(url, context) unless @shim.nil?
      SecurityService.new.rewrite_url(url, context)
    end

    def secure_cookies(context={})
      return @cookie_shim.call(context) unless @cookie_shim.nil?
      SecurityService.new.create_cookies(context)
    end

    def rewrite_url(&block)
      @shim = block
    end

    def create_cookies(&block)
      @cookie_shim = block
    end
  end
end
