// Empty file for future js
/* Override the search_context so it stops POSTing links which confuses
 * Rails and causes it to redirect to the wrong place. */
Blacklight.do_search_context_behavior = function() {}
