# Loads configuration information from the YAML file and then sets up the
# dropbox so that it can monitor using the guard-hydrant gem
#
# This makes a Dropbox object accessible in the controllers to query and find
# out what is available. See lib/hydrant/dropbox.rb for details on the API 
require 'hydrant/dropbox'

module Hydrant
  env = ENV['RAILS_ENV'] || 'development'
  Configuration = YAML::load(File.read(Rails.root.join('config', 'hydrant.yml')))[env]
  DropboxService = Dropbox.new Hydrant::Configuration['dropbox']['path']

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
