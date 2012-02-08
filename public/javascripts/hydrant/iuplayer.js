(function($){


$.widget("ui.iuplayer", {
	options: {
		library: 'jwplayer', // using jwplayer by default
		width: '480',
		height: '270',
		annotations: ''
	},
	_init: function(){ 
		console.log(this.options.width);
		
		// Initiates using a chosen player library
		if (this.options.library === 'jwplayer') {
			var jwmap = {
				'id': 'playerID',
				'width': this.options.width,
				'height': this.options.height,
				'dock': 'true',
				'controlbar.position': 'bottom',
				'bufferlength': '0',
				'repeat': 'always',
				modes: [
					{
						type: 'flash',
						src: "/jwplayer/player.swf",
						config: { skin: "/jwplayer/modieus5.zip"}
					}
					,{type:'html5'}
				]
			};
			
			if (this.options.playlistfile) {
				jwmap['playlistfile'] = this.options.playlistfile;
			    jwmap['playlist.position'] = this.options.playlistposition;
			    jwmap['playlist.size'] = 1;
			}
			else {
				jwmap['provider'] = this.options.provider;
				jwmap['streamer'] = this.options.streamer;
				jwmap['file'] = this.options.file;
			}
			
			jwplayer(this.element.attr('id')).setup(jwmap);			
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
