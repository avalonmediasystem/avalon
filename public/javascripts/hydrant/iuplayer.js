(function($){


$.widget("ui.iuplayer", {
	options: {
		library: 'jwplayer', // using jwplayer by default
		width: '480',
		height: '270',
		file: null,
		streamer: null,
		provider: null, // streaming RTMP by default
		annotations: ''
	},
	_init: function(){ 
		console.log(this.options.width);
		
		// Initiates using a chosen player library
		if (this.options.library === 'jwplayer') {
			jwplayer(this.element.attr('id')).setup({
				'id': 'playerID',
				'width': this.options.width,
				'height': this.options.height,
				'playlistfile': this.options.playlistfile,
			    'playlist.position': this.options.playlistposition,
			    'playlist.size': this.options.playlistsize,
				'dock': 'true',
				'controlbar.position': 'bottom',
				'bufferlength': '0',
				modes: [
					{
						type: 'flash',
						src: "/jwplayer/player.swf",
						config: { skin: "/jwplayer/modieus5.zip"}
					}
					,{type:'html5'}
				]
				// // 'provider': this.options.provider,
				// // 'streamer': this.options.streamer,

				// // 'file': this.options.file,
				// // 			'preload': 'all',
				// // 			'bufferlength': '0',
				// modes: [
				// 	{
				// 		type: 'flash',
				// 		src: "/jwplayer/player.swf",
				// 		config: { skin: "/jwplayer/modieus5.zip"}
				// 	},
				// 	{type:'html5'}
				// ]
			});			
		}
		
		// Reads annotations file and populates, if path exists
		if (this.options.annotations != '') {
			// Fetches XML file
			
			// Parses
			
			// Populates
		}
	}
});

})(jQuery);
