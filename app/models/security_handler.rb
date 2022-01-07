# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

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
