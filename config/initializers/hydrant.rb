# Loads configuration information from the YAML file and then sets up the
# dropbox so that it can monitor using the guard-hydrant gem
#
# This makes a Dropbox object accessible in the controllers to query and find
# out what is available. See lib/hydrant/dropbox.rb for details on the API 
require 'hydrant/dropbox'

module Hydrant
  DEFAULT_CONFIGURATION = {
    "dropbox"=>{},
    "matterhorn"=>{},
    "mediainfo"=>{"path"=>"/usr/local/bin/mediainfo"},
    "email"=>{},
    "streaming"=>{
      "server"=>:generic,
      "rtmp_base"=>"rtmp://localhost/avalon/",
      "http_base"=>"http://localhost:3000/streams/",
      "stream_token_ttl"=>20
    }
   }

  env = ENV['RAILS_ENV'] || 'development'
  Configuration = DEFAULT_CONFIGURATION.deep_merge(YAML::load(File.read(Rails.root.join('config', 'hydrant.yml')))[env])
  ['dropbox','matterhorn','mediainfo','email','streaming'].each { |key| Configuration[key] ||= {} }
  DropboxService = Dropbox.new Hydrant::Configuration['dropbox']['path']
  begin
    mipath = Hydrant::Configuration['mediainfo']['path']
    unless mipath.blank? 
      Mediainfo.path = Hydrant::Configuration['mediainfo']['path']
    end
    url_handler_class = Hydrant::Configuration['streaming']['server'].to_s.classify
    Derivative.url_handler = UrlHandler.const_get(url_handler_class.to_sym)
  rescue
    #TODO log some helpful error here instead of silently failing
  end

  def self.matterhorn_config
    mh_server = Configuration['matterhorn']['root'].sub(%r{/+$},'')
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
