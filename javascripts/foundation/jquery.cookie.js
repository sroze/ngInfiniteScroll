/*!
 * jQuery Cookie Plugin v1.3
 * https://github.com/carhartl/jquery-cookie
 *
 * Copyright 2011, Klaus Hartl
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.opensource.org/licenses/GPL-2.0
 */
!function(e,n,o){function r(e){return e}function t(e){return decodeURIComponent(e.replace(i," "))}var i=/\+/g,u=e.cookie=function(i,a,s){if(a!==o){if(s=e.extend({},u.defaults,s),null===a&&(s.expires=-1),"number"==typeof s.expires){var p=s.expires,c=s.expires=new Date;c.setDate(c.getDate()+p)}return a=u.json?JSON.stringify(a):String(a),n.cookie=[encodeURIComponent(i),"=",u.raw?a:encodeURIComponent(a),s.expires?"; expires="+s.expires.toUTCString():"",s.path?"; path="+s.path:"",s.domain?"; domain="+s.domain:"",s.secure?"; secure":""].join("")}for(var f=u.raw?r:t,l=n.cookie.split("; "),d=0,m=l.length;m>d;d++){var x=l[d].split("=");if(f(x.shift())===i){var g=f(x.join("="));return u.json?JSON.parse(g):g}}return null};u.defaults={},e.removeCookie=function(n,o){return null!==e.cookie(n)?(e.cookie(n,null,o),!0):!1}}(jQuery,document);