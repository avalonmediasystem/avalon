class SecurityHandler
  class << self
    def secure_url(url, context={})
      if @shim.nil?
        url
      else
        @shim.call(url, context)
      end
    end
    
    def rewrite_url(&block)
      @shim = block
    end
  end
end
