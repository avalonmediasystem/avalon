module Avalon

  class Config
    DEFAULT_CONFIGURATION = {
      "dropbox"=>{},
      "fedora"=>{"namespace"=>"avalon"},
      "ffmpeg"=>{"path"=>"/usr/local/bin/ffmpeg"},
      "mediainfo"=>{"path"=>"/usr/local/bin/mediainfo"},
      "email"=>{},
      "streaming"=>{
        "server"=>:generic,
        "content_path"=>File.join(Rails.root,"red5/webapps/avalon/streams"),
        "rtmp_base"=>"rtmp://localhost/avalon/",
        "http_base"=>"http://localhost:3000/streams/",
        "stream_token_ttl"=>20,
        "default_quality"=>'low'
      },
      'controlled_vocabulary' => {'path'=>'config/controlled_vocabulary.yml'},
      'master_file_management' => {'strategy'=>'none'}
    }
    
    def initialize
      @config = DEFAULT_CONFIGURATION.deep_merge(load_configuration)
      ['dropbox','matterhorn','mediainfo','email','streaming'].each { |key| @config[key] ||= {} }
      begin
        mipath = lookup('mediainfo.path')
        Mediainfo.path = mipath unless mipath.blank? 
      rescue Exception => e
        Rails.logger.fatal "Initialization failed"
        Rails.logger.fatal e.backtrace
        raise
      end
    end
    
    def config_file
      Rails.root.join('config', 'avalon.yml')
    end
    
    def load_configuration
      if File.exists?(config_file)
        load_configuration_from_file
      else
        load_configuration_from_environment
      end
    end
    
    def load_configuration_from_environment
      config_hash = {
        "dropbox"=>
          {"path"=>ENV['DROPBOX_PATH'],
           "upload_uri"=>ENV['DROPBOX_URI']},
         "fedora"=>{"namespace"=>ENV['FEDORA_NAMESPACE']},
         "ffmpeg"=>{"path"=>ENV['FFMPEG_PATH']},
         "mediainfo"=>{"path"=>ENV['MEDIAINFO_PATH']},
         "email"=>
          {"comments"=>ENV['EMAIL_COMMENTS'],
           "notification"=>ENV['EMAIL_NOTIFICATION'],
           "support"=>ENV['EMAIL_SUPPORT'],
           "mailer"=>
            {"smtp"=>
              {"address"=>ENV['SMTP_ADDRESS'],
              "port"=>coerce(ENV['SMTP_PORT'],:to_i),
              "domain"=>ENV['SMTP_DOMAIN'],
              "user_name"=>ENV['SMTP_USER_NAME'],
              "password"=>ENV['SMTP_PASSWORD'],
              "authentication"=>ENV['SMTP_AUTHENTICATION'],
              "enable_starttls_auto"=>ENV['SMTP_ENABLE_STARTTLS_AUTO'],
              "openssl_verify_mode"=>ENV['SMTP_OPENSSL_VERIFY_MODE']}}},
         "streaming"=>
          {"server"=>ENV['STREAM_SERVER'],
           "content_path"=>ENV['STREAM_BASE'],
           "rtmp_base"=>ENV['STREAM_RTMP_BASE'],
           "http_base"=>ENV['STREAM_HTTP_BASE'],
           "stream_token_ttl"=>coerce(ENV['STREAM_TOKEN_TTL'],:to_i),
           "default_quality"=>ENV['STREAM_DEFAULT_QUALITY']},
         "controlled_vocabulary"=>{"path"=>ENV['CONTROLLED_VOCABULARY']},
         "master_file_management"=>
          {"strategy"=>ENV['MASTER_FILE_STRATEGY'],
           "path"=>ENV['MASTER_FILE_PATH']},
         "name"=>ENV['APP_NAME'],
         "groups"=>ENV['SYSTEM_GROUPS'].to_s.split(/[,;:]\s*/)}
           
      if ENV['AVALON_URL'].present?
        avalon_url = URI.parse(ENV['AVALON_URL'])
        config_hash['domain'] = {
          'host'=>avalon_url.host,
          'port'=>avalon_url.port,
          'protocol'=>avalon_url.scheme
        }
      end
      
      if ENV['SRU_URL'].present?
        config_hash['bib_retriever'] = {
          'protocol'=>'sru',
          'url'=>ENV['SRU_URL'],
          'query'=>ENV['SRU_QUERY'],
          'namespace'=>ENV['SRU_NAMESPACE']
        }
      elsif ENV['Z3950_HOST'].present?
        config_hash['bib_retriever'] = {
          'protocol'=>'zoom',
          'host'=>ENV['Z3950_HOST'],
          'port'=>coerce(ENV['Z3950_PORT'],:to_i),
          'database'=>ENV['Z3950_DATABASE'],
          'attribute'=>coerce(ENV['Z3950_ATTRIBUTE'],:to_i)
        }
      end

      deep_compact(config_hash) || {}
    end
    
    def load_configuration_from_file
      env = ENV['RAILS_ENV'] || 'development'
      YAML::load(File.read(config_file))[env]
    end

    def lookup(*path)
      path = path.first.split(/\./) if path.length == 1
      path.inject(@config) do |location, key|
        location.respond_to?(:keys) ? location[key] : nil
      end
    end
    
    def rehost(url, host=nil)
      if host.present?
        url.sub(%r{/localhost([/:])},"/#{host}\\1") 
      else
        url
      end
    end

    def method_missing(sym, *args, &block)
      super(sym, *args, &block) unless @config.respond_to?(sym)
      @config.send(sym, *args, &block)
    end
    
    private
    def coerce(value, method)
      value.nil? ? nil : value.send(method)
    end
    
    def deep_compact(value)
      if value.is_a?(Hash)
        new_value = value.dup
        new_value.each_pair { |k,v|
          compact_value = deep_compact(v)
          if compact_value.nil?
            new_value.delete(k)
          else
            new_value[k] = compact_value
          end
        }
        new_value.empty? ? nil : new_value
      else
        (value.nil? or (value.respond_to?(:empty?) and value.empty?)) ? nil : value
      end
    end
  end

  Configuration = Config.new
end
