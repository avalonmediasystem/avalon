mh_server = "http://129.79.32.147:8080"

MATTERHORN_CONFIG = {
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
