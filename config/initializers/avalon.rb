# Loads configuration information from the YAML file and then sets up the
# dropbox 
#
# This makes a Dropbox object accessible in the controllers to query and find
# out what is available. See lib/avalon/dropbox.rb for details on the API 
require 'avalon/dropbox'
require 'avalon/batch'

I18n.config.enforce_available_locales = true

module Avalon
  DEFAULT_CONFIGURATION = {
    "dropbox"=>{},
    "fedora"=>{"namespace"=>"avalon"},
    "matterhorn"=>{},
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

  env = ENV['RAILS_ENV'] || 'development'
  Configuration = DEFAULT_CONFIGURATION.deep_merge(YAML::load(File.read(Rails.root.join('config', 'avalon.yml')))[env])
  ['dropbox','matterhorn','mediainfo','email','streaming'].each { |key| Configuration[key] ||= {} }
  def Configuration.lookup(*path)
    path = path.first.split(/\./) if path.length == 1
    path.inject(self) do |location, key|
      location.respond_to?(:keys) ? location[key] : nil
    end
  end
  
  begin
    mipath = Avalon::Configuration.lookup('mediainfo.path')
    Mediainfo.path = mipath unless mipath.blank? 
  rescue Exception => e
    logger.fatal "Initialization failed"
    logger.fatal e.backtrace
    raise
  end

  def self.rehost(url, host=nil)
    if host.present?
      url.sub(%r{/localhost([/:])},"/#{host}\\1") 
    else
      url
    end
  end

  def self.matterhorn_config(host=nil)
    mh_server = self.rehost(Configuration['matterhorn']['root'].sub(%r{/+$},''), host)
    {
      "plugin_urls"=>{
        "analytics"=>"#{mh_server}/usertracking/footprint.xml",
        "annotation"=>"#{mh_server}/annotation/annotations.json",
        "description"=>{
          "episode"=>"#{mh_server}/search/episode.json",
          "stats"=>"#{mh_server}/usertracking/stats.json",
        },
        "search"=>"#{mh_server}/search/episode.json",
        "segments_text"=>"#{mh_server}/search/episode.json",
        "segments_ui"=>"#{mh_server}/search/episode.json",
        "segments"=>"#{mh_server}/search/episode.json",
        "series"=>{
          "series"=>"#{mh_server}/search/series.json",
          "episode"=>"#{mh_server}/search/episode.json"
        }
      },
      "mediaDebugInfo"=>{
        "mediaPackageId"=>"",
        "mediaUrlOne"=>"",
        "mediaUrlTwo"=>"",
        "mediaResolutionOne"=>"",
        "mediaResolutionTwo"=>"",
        "mimetypeOne"=>"",
        "mimetypeTwo"=>""
      }
    }
  end
end
