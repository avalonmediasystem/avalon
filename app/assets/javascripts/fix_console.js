/* 
 * Copyright 2011-2024, The Trustees of Indiana University and Northwestern
 *   University.  Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 * 
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software distributed
 *   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 *   CONDITIONS OF ANY KIND, either express or implied. See the License for the
 *   specific language governing permissions and limitations under the License.
 * ---  END LICENSE_HEADER BLOCK  ---
*/

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
