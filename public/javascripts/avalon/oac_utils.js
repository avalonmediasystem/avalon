

var SVG_NS = "http://www.w3.org/2000/svg";
var XLINK_NS = "http://www.w3.org/1999/xlink";
        
var opts = {base:'http://your-server-here.com/path/to/stuff/',
        namespaces: {
    			rdf:'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
    			rdfs:'http://www.w3.org/2001/01/rdf-schema#',
				dc:'http://purl.org/dc/elements/1.1/',
                dcterms:'http://purl.org/dc/terms/',
                dctype:'http://purl.org/dc/dcmitype/',
                oac:'http://www.openannotation.org/ns/',
                cnt:'http://www.w3.org/2008/content#',
                aos:'http://purl.org/ao/selectors/',
                foaf:'	http://xmlns.com/foaf/0.1/',
                
                ore:'http://www.openarchives.org/ore/terms/',
                dms:'http://dms.stanford.edu/ns/',
                exif:'http://www.w3.org/2003/12/exif/ns#'

                }
};

var topinfo = {'annotations' : {}, 'done':[], 'builtAnnos':[]}

// mfre.exec(frag) --> [full, x, y, w, h]
var mfRectRe = new RegExp('xywh=([0-9]+),([0-9]+),([0-9]+),([0-9]+)');
// mfNptRe.exect(frag) --> [full, npt, start, end]
var mfNptRe = new RegExp('t=(npt:)?([0-9.:]+)?,([0-9.:]+)?');


var textre = new RegExp('/text\\(\\)$');          
var slashs = new RegExp('^[/]+');
var xptr = new RegExp('^#?xpointer\\((.+)\\)$');
var attrq = new RegExp('\\[([^\\]]+)=([^\\]"]+)\\]', 'g')
var strrng = new RegExp('^string-range\\((.+),([0-9]+),([0-9]+)\\)')

function xptrToJQuery(xp) {
	// Strip xpointer(...)
	var xp = xp.replace(/^\s+|\s+$/g, '');
	var m = xp.match(xptr);
	if (m) {
		xp = m[1];
	}	
	// We want to support string-range(xp, start, end)
	xp = xp.replace(/^\s+|\s+$/g, '');
	m = xp.match(strrng);
	if (m) {
		xp = m[1];
		var start = parseInt(m[2]);
		var end = parseInt(m[3]);
		var wantsText = [start, end]
	} else {
		// /text() --> return that we want .text()
		var wantsText = false;
		m = xp.match(textre)
		if (m) {
			xp = xp.replace(textre, '');
			wantsText = true;
		}
	}
	//strip initial slashes
	xp = xp.replace(slashs, '');
	// Parent and Descendant axes
	xp = xp.replace(new RegExp('//', 'g'), ' ');
	xp = xp.replace(new RegExp('/', 'g'), ' > ');
	// Ensure quotes in attribute values
	xp = xp.replace(attrq, '[$1="$2"]');
	// id(bla) --> #bla
	xp = xp.replace(/id\((.+)\)/g, '#$1')
	// Final trim
	xp = xp.replace(/^\s+|\s+$/g, '');	
	return [xp, wantsText];	
}


function parseNptItem(npt) {
	if (npt.indexOf(':') > -1) {
		// [hh:]mm:ss[.xx]
		var arr = npt.split(':');
		var secs = parseFloat(arr.pop());
		var mins = parseInt(arr.pop());
		if (arr.length > 0) {
			var hrs = parseInt(arr.pop());
		} else { var hrs = 0 };
		return secs + (mins * 60) + (hrs * 3600);					
	} else {
		return parseFloat(npt)
	}
}


function rdf_to_list(qry, uri) {
	var l = [];
	var firsts = {};
	var rests = {};
	qry.where('?what rdf:first ?frst')
	.where('?what rdf:rest ?rst')
	.each(function() {firsts[this.what.value] = this.frst.value; rests[this.what.value] = this.rst.value});

	// Start list from first				
	l.push(firsts[uri]);
	var nxt = rests[uri];

	// And now iterate through linked list
	while (nxt) {			
		if (firsts[nxt] != undefined) {
			l.push(firsts[nxt]);		
		}
		nxt = rests[nxt];
	}
	return l;	
}

function isodate(d) {
    var dt = '' + d.getUTCFullYear();
    var m = '' + (d.getUTCMonth() + 1);
    m = m.length == 1 ? '0' + m : m;
    var dy = '' + d.getUTCDate();
    dy = dy.length == 1 ? '0' + dy : dy;
    var hr = '' + d.getUTCHours();
    hr = hr.length == 1 ? '0' + hr : hr;
    var mn = '' + d.getUTCMinutes();
    mn = mn.length == 1 ? '0' + mn : mn;
    var sc = '' + d.getUTCSeconds();
    sc = sc.length == 1 ? '0' + sc : sc;
    return dt + '-' + m + '-' + dy + ' ' + hr + ':' + mn + ':' + sc + ' UTC';
}
