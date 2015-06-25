module Avalon
  class DefaultStreamMapper
    Detail = Struct.new(:rtmp_base, :http_base, :path, :filename, :extension) { def get_binding; binding; end }
    
    attr_accessor :streaming_server
    
    def initialize
      @streaming_server = Avalon::Configuration.lookup('streaming.server')
      @handler_config = YAML.load(File.read(Rails.root.join('config/url_handlers.yml')))
    end
    
    def url_handler
      @handler_config[self.streaming_server.to_s]
    end

    def base_url_for(path, protocol)
      Avalon::Configuration.lookup("streaming.#{protocol}_base")
    end

    def stream_details_for(path)
      content_path = Pathname.new(Avalon::Configuration.lookup("streaming.content_path"))
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
