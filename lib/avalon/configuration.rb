# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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
  class Config
    DEFAULT_CONFIGURATION = {
      "dropbox"=>{},
      "fedora"=>{"namespace"=>"avalon", "base_path"=>""},
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
        logger.fatal "Initialization failed"
        logger.fatal e.backtrace
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

    ENVIRONMENT_MAP = {
      "BASE_URL" => { key: 'domain', read_proc: ->(v){read_avalon_url(v)}, write_proc: ->(v){write_avalon_url(v)} },
      "DROPBOX_PATH" => { key: "dropbox.path" },
      "DROPBOX_URI" => { key: "dropbox.upload_uri" },
      "FEDORA_BASE_PATH" => { key: "fedora.base_path" },
      "FEDORA_NAMESPACE" => { key: "fedora.namespace" },
      "FFMPEG_PATH" => { key: "ffmpeg.path" },
      "MEDIA_PATH" => { key: "matterhorn.media_path" },
      "MEDIAINFO_PATH" => { key: "mediainfo.path" },
      "EMAIL_COMMENTS" => { key: "email.comments" },
      "EMAIL_NOTIFICATION" => { key: "email.notification" },
      "EMAIL_SUPPORT" => { key: "email.support" },
      "SMTP_ADDRESS" => { key: "email.mailer.smtp.address" },
      "SMTP_PORT" => { key: "email.mailer.smtp.port", read_proc: ->(v){coerce(v, :to_i)} },
      "SMTP_DOMAIN" => { key: "email.mailer.smtp.domain" },
      "SMTP_USER_NAME" => { key: "email.mailer.smtp.user_name" },
      "SMTP_PASSWORD" => { key: "email.mailer.smtp.password" },
      "SMTP_AUTHENTICATION" => { key: "email.mailer.smtp.authentication" },
      "SMTP_ENABLE_STARTTLS_AUTO" => { key: "email.mailer.smtp.enable_starttls_auto" },
      "SMTP_OPENSSL_VERIFY_MODE" => { key: "email.mailer.smtp.openssl_verify_mode" },
      "SRU_URL" => { key: "bib_retriever.url", infer: { key: 'bib_retriever.protocol', value: 'sru' }  },
      "SRU_QUERY" => { key: "bib_retriever.query" },
      "SRU_NAMESPACE" => { key: "bib_retriever.namespace" },
      "STREAM_SERVER" => { key: "streaming.server" },
      "STREAM_BASE" => { key: "streaming.content_path" },
      "STREAM_RTMP_BASE" => { key: "streaming.rtmp_base" },
      "STREAM_HTTP_BASE" => { key: "streaming.http_base" },
      "STREAM_TOKEN_TTL" => { key: "streaming.stream_token_ttl", read_proc: ->(v){coerce(v, :to_i)} },
      "STREAM_DEFAULT_QUALITY" => { key: "streaming.default_quality" },
      "CONTROLLED_VOCABULARY" => { key: "controlled_vocabulary.path" },
      "MASTER_FILE_STRATEGY" => { key: "master_file_management.strategy" },
      "MASTER_FILE_PATH" => { key: "master_file_management.path" },
      "APP_NAME" => { key: "name" },
      "SYSTEM_GROUPS" => { key: "groups.system_groups", read_proc: ->(v){v.to_s.split(/[,;:]\s*/)}, write_proc: ->(v){v.join(',')} },
      "Z3950_HOST" => { key: "bib_retriever.host", infer: { key: 'bib_retriever.protocol', value: 'zoom' } },
      "Z3950_PORT" => { key: "bib_retriever.port", read_proc: ->(v){coerce(v, :to_i)} },
      "Z3950_DATABASE" => { key: "bib_retriever.database" },
      "Z3950_ATTRIBUTE" => { key: "bib_retriever.attribute", read_proc: ->(v){coerce(v, :to_i)} },
      "FLASH_MESSAGE_TYPE" => { key: "flash_message.type" },
      "FLASH_MESSAGE" => { key: "flash_message.message" }
    }

    ENV.keys.select { |k| k =~ /^AVALON_/ }.each do |key|
      ENV[key.split(/_/,2).last] = ENV[key]
    end


    def set(key, value, hash=@config_hash)
      this_key,sub_key = key.split(/\./,2)
      if sub_key.nil?
        hash[this_key] = value
      else
        hash[this_key] ||= {}
        set(sub_key,value,hash[this_key])
      end
      hash
    end

    def from_env
      config_hash = {}
      ENVIRONMENT_MAP.each_pair do |key,spec|
        val = ENV[key]
        val = spec[:read_proc].call(val) unless spec[:read_proc].nil?
        if val.present?
          set(spec[:key],val,config_hash)
        end
        if spec[:infer]
          set(spec[:infer][:key],spec[:infer][:value],config_hash)
        end
      end
      config_hash
    end

    def to_env
      result = {}
      ENVIRONMENT_MAP.each_pair do |key,spec|
        next if spec[:infer] and lookup(spec[:infer][:key]) != spec[:infer][:value]
        val = lookup(spec[:key])
        val = spec[:write_proc].call(val) unless spec[:write_proc].nil?
        result[key] = val unless val.nil?
      end

      url = URI.parse(ActiveFedora.fedora_config.credentials[:url])
      url.user = ActiveFedora.fedora_config.credentials[:user]
      url.password = ActiveFedora.fedora_config.credentials[:password]
      result['FEDORA_URL'] = url.to_s
      result['FEDORA_BASE_PATH'] = ActiveFedora.fedora_config.credentials[:base_path]

      begin
        url = URI.parse(Rubyhorn.config_for_environment[:url])
        url.user = Rubyhorn.config_for_environment[:user]
        url.password = Rubyhorn.config_for_environment[:password]
        result['MATTERHORN_URL'] = url.to_s
      rescue NameError, LoadError
      end

      result['SOLR_URL'] = ActiveFedora.solr_config[:url]

      config = ActiveRecord::Base.connection_config
      path_key = config[:database].starts_with?('/') ? :path : :opaque
      url = Addressable::URI.parse(URI::Generic.build(scheme: config[:adapter], host: config[:host], user: config[:username], password: config[:password], port: config[:port], path_key => config[:database]))
      url.query_values = config.reject { |k,v| [:adapter,:host,:username,:password,:port,:database].include?(k) }
      result['DATABASE_URL'] = url.to_s

      result['SECRET_KEY_BASE'] = Avalon::Application.config.secret_key_base
      result.collect { |key,val| [key,val.to_s.inspect].join('=') }.join("\n")
    end

    def load_configuration_from_environment
      deep_compact(from_env)
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
    class << self
      def coerce(value, method)
        value.nil? ? nil : value.send(method)
      end

      def read_avalon_url(v)
        return({}) if v.nil?
        avalon_url = URI.parse(v)
        { 'host'=>avalon_url.host, 'port'=>avalon_url.port, 'protocol'=>avalon_url.scheme }
      end

      def write_avalon_url(v)
        URI::Generic.build(scheme: v.fetch('protocol','http'), host: v['host'], port: v['port']).to_s
      end
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
