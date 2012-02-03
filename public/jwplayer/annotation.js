(function(jwplayer){

  var template = function(player, config, div) {
	
    var _j = $(div);	
    var _ready = false;
    var _rail = null;
    var _controlbar = null;

    function setup(evt) {
		
        // Create the Annotation
        _createAnnotation();

        // Setting variables
        _rail = $("#" + player.id + "_jwplayer_controlbar_timeSliderRail");
        _controlbar = $("#" + player.id + "_jwplayer_controlbar_elements");

        // If everything went fine...
        if(1===_rail.length && 1===_controlbar.length)
        {
            _ready = true;
            _controlbar.append(_j);
			console.log('tada');
        }
    };
	
    player.onReady(setup);

    function _createAnnotation()
    {
        // Initialize tooltip
        // ==================
        var map = {};
		_j.html(config.text);
        
        // Background
        // ==========
	    map.color = 'red';
        map.position = 'absolute';
        map.width = "41px";
        map.height = "22px";
		_j.css(map);
	}

    this.resize = function(width, height) {
		var map = {};
		map.left = Math.round(width/2) + 'px';
		map.bottom = -20 + 'px';
		_j.css(map);
		console.log(width);
		//div.style.left = (_rail.offset().left) + 'px';
		//div.style.top = (_rail.offset().top - Math.ceil(height/2)) + 'px';
	};
	
	
    
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

  };

  jwplayer().registerPlugin('annotation', template);

})(jwplayer);