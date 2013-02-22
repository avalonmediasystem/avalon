
// Simple wrapper on fetchTriples
function fetch_annotations(uri, callback) {
	var qry = $.rdf(opts);
	fetchTriples(uri, qry, cb_process_annoList, callback);
}

//Pull rdf/xml file and parse to triples
function fetchTriples(uri, qry, fn, callback) {
	// Check we've not already pulled this uri
	if (topinfo['done'].indexOf(uri) > -1) {
		fn(qry,uri, callback);
	} else {
		topinfo['done'].push(uri);
	}
	
	$.ajax({ 
        url: uri,
        accepts: "application/rdf+xml",
        success: function(data, status, xhr) {
			try {
    			var resp = qry.databank.load(data);
    		} catch(e) {
    			alert('Broken RDF/XML: ' + e)
    		}
    		if (qry != null) {
        		fn(qry, uri, callback);
        	}
        	return;
        },
        error:  function(XMLHttpRequest, status, errorThrown) {
                alert('Can not fetch data from ' + uri);
        }
    });
}

function cb_process_annoList(qry, uri, callback) {

	var externalFiles = {};
	var annos = buildAllAnnos(qry);
	var allAnnos = topinfo['annotations'];

	try {
	
	for (var a=0,anno;anno=annos[a];a++) {

		var tgts = [];
		for (var t=0,target;target=anno.targets[t];t++) {
			
			if (target.partOf != null) {
				var tid = target.partOf.id;
			} else {
				var tid = target.id;
			}	
			tgts.push(tid);
			
			if (allAnnos[tid] == undefined) {
				allAnnos[tid] = [];
			}
			allAnnos[tid].push(anno);
				
			if (target.fragmentType == 'xml') {
				var pid = target.partOf.id;
				if (externalFiles[pid]== undefined) {
					externalFiles[pid] = [];
				}
				externalFiles[pid].push([anno, target]);
				anno.finished -= 1;
			}
			if (target.constraint != null && !target.constraint.value) {
				var pid = target.constraint.id;
				if (externalFiles[pid]== undefined) {
					externalFiles[pid] = [];
				}
				externalFiles[pid].push([anno, target.constraint]);
				anno.finished -= 1;			
			}
		}
			
		// And maybe load resources for the Body
		if (anno.body.fragmentType == 'xml') {
			var pid = anno.body.partOf.id;
			if (externalFiles[pid]== undefined) {
				externalFiles[pid] = [];
			}
			externalFiles[pid].push([anno, anno.body]);
			anno.finished -= 1;
		}
		if (anno.body.constraint != null && !anno.body.constraint.value) {
			var pid = anno.body.constraint.id;
			if (externalFiles[pid]== undefined) {
				externalFiles[pid] = [];
			}
			externalFiles[pid].push([anno, anno.body.constraint]);
			anno.finished -= 1;			
		}
	}
	
	
	} catch(e) {alert('error: ' + e) }
	
	
	topinfo['annotations'] = allAnnos;

	// Try to force GC on the query
	delete qry.databank;
	qry = null;
	
	// Do something with the annotations here
	callback(allAnnos);
	
	// And launch AJAX queries for any external XML docs
	for (var uri in externalFiles) {
		$.ajax(
				{url: uri, dataType: "xml",
					success: function(data, status, xhr) {
					try {							
							// We have the XML now, so walk through all annos for it
							var remotes = externalFiles[uri];							
							for (var i=0,inf; inf=remotes[i]; i++) {
								var anno = inf[0];
								var what = inf[1];
								if (what.fragmentType == 'xml') {
									var sel = what.fragmentInfo[0];
									var txtsel = what.fragmentInfo[1];
									var btxt = $(data).find(sel).text().substring(txtsel[0], txtsel[1]);
								} else {
									var btxt = data;
								}
								what.value = btxt;
								anno.finished += 1;
							}
							// Do something with the annos here
							process_annotations();

						} catch(e) {
							alert('Broken data in ' + anno.id +  ':' + e)
						}
				    },
			    	error:  function(XMLHttpRequest, status, errorThrown) {
			            alert('Can not fetch data from ' + uri);
			    	}
				}	
		);
	}
}