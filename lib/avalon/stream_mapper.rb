# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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


module Avalon
  class DefaultStreamMapper
    Detail = Struct.new(:rtmp_base, :http_base, :path, :filename, :extension) { def get_binding; binding; end }

    attr_accessor :streaming_server

    def initialize
      @streaming_server = Settings.streaming.server
      @handler_config = YAML.load(File.read(Rails.root.join('config/url_handlers.yml')))
    end

    def url_handler
      @handler_config[self.streaming_server.to_s]
    end

    def base_url_for(path, protocol)
      Settings.streaming["#{protocol}_base"]
    end

    def stream_details_for(path)
      content_path = Pathname.new(Settings.streaming.content_path)
      p = Pathname.new(path).relative_path_from(content_path)
      Detail.new(base_url_for(path,'rtmp'),base_url_for(path,'http'),p.dirname,p.basename(p.extname),p.extname[1..-1])
    end

    def map(path, protocol, format)
      template = ERB.new(self.url_handler[protocol][format])
      template.result(stream_details_for(path).get_binding)
    end
  end

  StreamMapper = DefaultStreamMapper.new
end
