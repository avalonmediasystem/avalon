/**
 * Call once at beginning to ensure your app can safely call console.log() and
 * console.dir(), even on browsers that don't support it.  You may not get useful
 * logging on those browers, but at least you won't generate errors.
 *
 * @param  alertFallback - if 'true', all logs become alerts, if necessary.
 *   (not usually suitable for production)
 */
(function (alertFallback)
{
    if (typeof console === "undefined")
    {
        console = {}; // define it if it doesn't exist already
    }
    if (typeof console.log === "undefined")
    {
        if (alertFallback) { console.log = function(msg) { alert(msg); }; }
        else { console.log = function() {}; }
    }
    if (typeof console.dir === "undefined")
    {
        if (alertFallback)
        {
            // THIS COULD BE IMPROVED… maybe list all the object properties?
            console.dir = function(obj) { alert("DIR: "+obj); };
        }
        else { console.dir = function() {}; }
    }
})(false)