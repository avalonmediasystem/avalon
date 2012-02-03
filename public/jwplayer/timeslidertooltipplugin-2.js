(function(jwplayer)
{
    var template = function(player, config, div) 
    {
        var _j = $(div);
		var _marker = $('<div id="marker">XXX</div>');
		var _markerCreated = false;
		var _markerTime = 10;
        var _ready = false;
        var _rail = null;
        var _controlbar = null;
        
        function setup(evt) 
        {
            // Parsing the config object
            _parseConfig();
            
            // Create the Tooltip
            _createTooltip();
            
            // Setting variables
            _rail = $("#" + player.id + "_jwplayer_controlbar_timeSliderRail");
            _controlbar = $("#" + player.id + "_jwplayer_controlbar_elements");
            
            // If everything went fine...
            if(1===_rail.length && 1===_controlbar.length)
            {
                _ready = true;
                _controlbar.append(_j);
				$('#mediaplayer').append(_marker);
				//_controlbar.append(_marker);
                _controlbar.bind('mousemove', _mousemove);
                _controlbar.bind('mouseout', _mouseout);
            }
        };
        
        player.onReady(setup);
        
        this.resize = function(width, height) 
        {
            var map = {};
            map.left = Math.round(width/2) + 'px';
            var mb = isNaN(config.marginbottom) ? 0 : config.marginbottom;
            var pos = _controlbar.offset().top;
            
            _controlbar.append(_j);
            
            map.bottom = (_j.height() - mb) + 'px';
            _j.css(map);
        };
        
        function _parseConfig()
        {
            config.displayhours = ("true" == String(config.displayhours)) ? true : false;
            var marginBottom = parseInt(config.marginbottom);
            config.marginbottom = isNaN(marginBottom) ? 0 : marginBottom;
            var labelHeight = parseInt(config.labelheight);
            config.labelheight = (isNaN(labelHeight)) ? 17 : labelHeight;
            config.font = (!config.font) ? "Arial,sans-serif" : config.font;
            var fontSize = parseInt(config.fontsize);
            config.fontsize = isNaN(fontSize) ? 11 : fontSize;
            var fontColor = config.fontcolor;
            config.fontcolor = (!fontColor) ? "#000" : fontColor;
            var fontWeight = config.fontweight;
            config.fontweight = (fontWeight!="normal" && fontWeight!="bold") ? "normal" : fontWeight;
            var fontStyle = config.fontstyle;
            config.fontstyle = (fontStyle!="normal" && fontStyle!="italic") ? "normal" : fontStyle;
            config.defaultImage = "data:image/png;base64,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";
            config.image = (null!=config.image) ? config.image : config.defaultImage;
            
        };
        
        function _createTooltip()
        {
            // Initialize tooltip
            // ==================
            var map = {};
            div.innerHTML = "...";
            
            _show(false);
            
            // Background
            // ==========
            map.width = "82px";
            map.height = "22px";
            map.background = "url('" + config.defaultImage + "') left top no-repeat transparent";
            var img = new Image();
            img.onload = function() 
            {
                div.style.background = "url('" + config.image + "') left top no-repeat transparent";
                div.style.width = this.width + "px";
                div.style.height = this.height + "px";
            };
            img.src = config.image;
            
            // Applying
            // ========
            map.position = 'absolute';
            map.color = config.fontcolor;
            map.fontFamily = config.font;
            map.fontSize = config.fontsize + "px";
            map.fontWeight = config.fontweight;
            map.color = config.fontcolor;
            map.fontStyle = config.fontstyle;
            map.textAlign = "center";
            map.lineHeight = config.labelheight + "px";
            map.pointerEvents = "none";
            _j.css(map);
        };
		
		//player.onPlay(_createMarker);
		
		function _createMarker()
		{	
			if (_markerCreated) 
			{
				return;
			}
			
			var dur = player.getDuration();
			var width = _rail.width();
			var percent = _markerTime/dur;
			var left = Math.ceil(percent*width) + 65;//+ _rail.offset().left - _rail.width();
			//console.log(_marker.parent());
            var map = {};
            map.position = 'absolute';
			map.left = left + 'px';
			map.bottom = 4 + 'px';
			map.color = 'red';
			_marker.css(map);
		}
        
        function _show(state)
        {
            div.style.display = (false===state) ? "none" : "block";
        };
        
        function _mousemove(event)
        {
            var dur = player.getDuration();
            if(_ready && dur > 0)
            {
                var x_pos = event.pageX - _rail.offset().left;
                var width = _rail.width();
                var percent = x_pos/width;
                var tooltip_x = event.pageX - _j.parent().offset().left;
                div.innerHTML = _toTimeString(Math.round(percent*dur));
                tooltip_x -= Math.ceil(_j.width()/2);
                div.style.left = tooltip_x + "px";
                _show(x_pos >= 0 && x_pos <= width);
            }
            else
            {
                _show(false)
            }
        };
        
        function _mouseout(event)
        {
            _show(false)
        };
        
        function _toTimeString(n)
        {
            var time_str = "";
            if (n >= 3600 && true===config.displayhours)
            {   // Longer than one hour
                var hours = Math.floor(n / 3600);
                time_str += Math.floor(n / 3600) + ":";
                n -= 3600 * hours;
            }
            time_str += _pad(Math.floor(n / 60), 2) + ":" + _pad(Math.floor(n % 60), 2);

			if (n == 10)
			{
				time_str = "Cool";
			} else 	if (n == 20)
			{
				time_str = "Nifty";
			}
            return time_str;
        };
        
        function _pad(n, padLength)
        {
            var str = n.toString();
            while ( str.length < padLength )
            {
                str = "0" + str;
            }
            return str;
        };

    };
    jwplayer().registerPlugin('timeslidertooltipplugin', template, "timeslidertooltipplugin-1");
})(jwplayer);