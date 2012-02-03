

function buildAllAnnos(query, type) {
	query.reset();
	if (type != undefined) {
		var typres = query.where('?anno a ' + type);
	} 
	var annos = {};
	var result = query.where('?anno oac:hasBody ?body')
	.each(function() {annos[this.anno.value.toString()]=1;});
	query.reset();
	
// This is inane, but faster than anything involving queries	
	return rdfToJson(annos, query.databank.dump());
}


// Sometimes the dump syntax has multiple copies
// if there are circular refs. Probably a bug in RDFQuery
function uniqueValueList(list) {
	var hash = {};
	for (var i=0,item;item=list[i];i++) {
		hash[item.value] = 1;
	}
	var res = [];
	for (j in hash) {
		res.push(j);
	}
	return res;
}

function rdfToJson(annos, dump) {
	var nss = opts.namespaces;
	var annoObjs = [];
					
	for (var id in annos) {
		if (topinfo['builtAnnos'].indexOf(id) > -1) {
			continue;
		} else {
			topinfo['builtAnnos'].push(id);
		}
		
		var anno = new jAnno(id);
		anno.extractInfo(dump);
		// Must be exactly one body. Ignore past first
		var bodid = dump[id][nss['oac']+'hasBody'][0]['value'];
		var bod = new jBodyTarget(bodid);
		bod.extractInfo(dump);
		anno.body = bod;
		var tgts = dump[id][nss['oac']+'hasTarget'];
		var uniqtgts = uniqueValueList(tgts);
		for (t in uniqtgts) {
			var tid = uniqtgts[t];
			var tgt = new jBodyTarget(tid);
			tgt.extractInfo(dump);
			anno.targets.push(tgt)
		}
		annoObjs.push(anno);
	}
	return annoObjs;
}


function jAnno(id) {
	this.id = id;
	this.types = [];
	this.creator = null;
	this.title = "";
	this.body = null;
	this.targets = [];	
	this.zOrder = 0;
	this.finished = 1;
	this.painted = 0;
}


jAnno.prototype.extractInfo = function(info) {
	var nss = opts.namespaces;
	var me = info[this.id]
	var typs = me[nss['rdf']+'type'];	
	this.types = uniqueValueList(typs);
	if (me[nss['dc']+'title'] != undefined) {
		this.title = me[nss['dc']+'title'][0]['value'];
	}
	
}

var extractSimple = function(info) {

	var me = info[this.id];
	if (me == undefined) {
		// No info about resource at all
		return;
	}
	var nss = opts.namespaces;
	
	if (me[nss['rdf']+'type'] != undefined) {
		var typs = me[nss['rdf']+'type'];	
		this.types= uniqueValueList(typs);
	} 
	if (me[nss['dc']+'title'] != undefined) {
		this.title = me[nss['dc']+'title'][0]['value'];
	}
	if (me[nss['cnt']+'chars'] != undefined) {
		this.value = me[nss['cnt']+'chars'][0]['value'];
	}
	if (me[nss['dc']+'format'] != undefined) {
		this.format = me[nss['dc']+'format'][0]['value'];
	}
	if (me[nss['exif']+'height'] != undefined) {
		this.height = parseInt(me[nss['exif']+'height'][0]['value']);
	}
	if (me[nss['exif']+'width'] != undefined) {
		this.width = parseInt(me[nss['exif']+'width'][0]['value']);
	}
	if (me[nss['dc']+'extent'] != undefined) {
		this.extent = parseInt(me[nss['dc']+'extent'][0]['value']);
	}
	
}


function jBodyTarget(id) {
	this.id = id;
	this.fragments = [];
	
	var hidx = id.indexOf('#');
	if (hidx > -1) {
		// Check for fragments and try to parse
		var frags = id.substring(hidx+1, 1000).split('&');
		for (var i in frags) {
			this.fragments.push(getFragObj(frags[i]));
		}
	}
	
	this.types = [];
	this.title = "";
	this.creator = null;
	this.value = "";
	this.constraint = null;
	this.partOf = null;

}

// Gets a frag object from a frag string
function getFragObj(frag) {
	var fragObj = new jFragment();
	if (frag.substring(0,2) == 'xy') {
		// xywh=  (x,y,w,h)
		var info = mfRectRe.exec(frag)
		fragObj.fragmentInfo = [parseInt(info[1]), parseInt(info[2]), parseInt(info[3]), parseInt(info[4])];
		fragObj.fragmentType = 'rect';
	} else if (frag.substring(0,2) == 'xp') {
		// xpointer => (jquerySelect, textInfo)
		var info = xptrToJQuery(frag);
		fragObj.fragmentType = 'xml';
		fragObj.fragmentInfo = info;
	} else if (frag.substring(0,2) == 't=') {
		// t= (start, end)
		var info = mfNptRe.exec(frag);
		fragObj.fragmentInfo = [parseNptItem(info[2]), parseNptItem(info[3])]	;
		fragObj.fragmentType = 'time';		
	}
	
	return fragObj;
}

function jFragment() {
	this.fragmentType = null;
	this.fragmentInfo = null;
}

jBodyTarget.prototype.extractSimple = extractSimple;

jBodyTarget.prototype.extractInfo = function(info) {
	var nss = opts.namespaces;
	var me = info[this.id];
	if (me == undefined) {
		// No info about resource at all :(
		return;
	}
	
	this.extractSimple(info);

	if (me[nss['dcterms']+'isPartOf'] != undefined) {
		var pid = me[nss['dcterms']+'isPartOf'][0]['value'];
		var partOf = new jResource(pid);
		this.partOf = partOf;
		partOf.extractInfo(info);

	} 
	
	// Check for constraint
	if (this.partOf == null) {
		if (me[nss['oac']+'constrains'] != undefined) {
			var pid = me[nss['oac']+'constrains'][0]['value'];
			var partOf = new jResource(pid);
			partOf.extractInfo(info);
			this.partOf = partOf;
			
			var cid = me[nss['oac']+'constrainedBy'][0]['value'];
			var constraint = new jConstraint(cid);
			constraint.extractInfo(info);
			this.constraint = constraint;		                                                  
		}
	}
	
}

function jConstraint(id) {
	this.id = id;
	this.format = '';
	this.value = "";
	this.creator = null;
	this.title = "";
	this.types = [];
}

jConstraint.prototype.extractSimple = extractSimple;

jConstraint.prototype.extractInfo = function(info) {
	var nss = opts.namespaces;
	var me = info[this.id];
	this.extractSimple(info);
	
	if (me[nss['aos']+'offset'] != undefined) {
		this.offset = me[nss['aos']+'offset'][0]['value'];
	}
	if (me[nss['aos']+'range'] != undefined) {
		this.range = me[nss['aos']+'range'][0]['value'];
	}
	if (me[nss['aos']+'prefix'] != undefined) {
		this.prefix = me[nss['aos']+'prefix'][0]['value'];
	}
	if (me[nss['aos']+'postfix'] != undefined) {
		this.postfix = me[nss['aos']+'postfix'][0]['value'];
	}
	if (me[nss['aos']+'exact'] != undefined) {
		this.exact = me[nss['aos']+'exact'][0]['value'];
	}
}


function jResource(id) {
	this.id = id;
	this.types = [];
	this.title = "";
	this.creator = null;
	this.value = "";
	
	this.format = "";
	this.height = 0;
	this.width = 0;
	this.extent = 0;

}

jResource.prototype.extractInfo = extractSimple;
	

function jAgent(id) {
	this.name = "";
	this.email = "";
	this.web = "";
}

