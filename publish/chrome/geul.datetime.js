/*
 * Make <time> prettier
 * Author: Jaeho Shin <netj@sparcs.org>
 * Created: 2010-05-20
 */

//// Code for parsing date/times in ISO 8601 format
//  Borrowed from John Resig's.
//  Other candidates were:
//   http://delete.me.uk/2005/03/iso8601.html
//   http://code.google.com/p/datejs/
function parseISODate(isodt) {
    var d;
    var s = (isodt || "").replace(/-/g,"/").replace(/[TZ]/g," ");
    var m = s.match(/(.*)([+-])(\d\d)(:?(\d\d))?$/);
    if (m) {
        d = new Date(m[1]);
        var tzH = parseInt(m[3].replace(/^0*/,""));
        var tzM = parseInt(m[5].replace(/^0*/,"").replace(/^$/,"0"));
        var tzOffset = tzH * 60 + tzM;
        if (m[2] == '-')
            tzOffset *= -1;
        var offset = d.getTimezoneOffset() + tzOffset;
        if (offset != 0)
            d.setTime(d.getTime() + offset*60*1000);
    } else {
        d = new Date(s);
    }
    return d;
}


//// Code for computing relative date/times
//  Derived from: http://ejohn.org/blog/javascript-pretty-date/
/*
 * JavaScript Pretty Date
 * Copyright (c) 2008 John Resig (jquery.com)
 * Licensed under the MIT license.
 */

// Takes an ISO time and returns a string representing how
// long ago the date represents.
function relativeDate(date) {
    var diff = (((new Date()).getTime() - date.getTime()) / 1000),
        day_diff = Math.floor(diff / 86400);

    if ( isNaN(day_diff) || day_diff < 0 || day_diff >= 31 )
        return null;

    if (navigator.language && navigator.language.match(/^ko/))
        return day_diff == 0 && (
                diff < 60 && "방금" ||
                diff < 3600 && "약 " + Math.floor( diff / 60 ) + "분 전에" ||
                diff < 86400 && "약 " + Math.floor( diff / 3600 ) + "시간 전에"
                ) ||
            day_diff == 1 && "어제" ||
            day_diff < 7 && day_diff + "일 전에" ||
            day_diff < 31 && "약 " + Math.round( day_diff / 7 ) + "주 전에";
    return day_diff == 0 && (
            diff < 60 && "just now" ||
            diff < 120 && "a minute ago" ||
            diff < 3600 && Math.floor( diff / 60 ) + " minutes ago" ||
            diff < 7200 && "an hour ago" ||
            diff < 86400 && Math.floor( diff / 3600 ) + " hours ago"
            ) ||
        day_diff == 1 && "yesterday" ||
        day_diff < 7 && day_diff + " days ago" ||
        day_diff < 11 && "about a week ago" ||
        day_diff < 31 && "about " + Math.round( day_diff / 7 ) + " weeks ago";
}


jQuery.fn.prettyDate = function() {
    return this.each(function() {
            var isodt = this.getAttribute("datetime");
            var date = parseISODate(isodt);
            var rel = relativeDate(date);
            var abs;
            if (rel) {
                jQuery(this).text(rel);
            } else {
                abs = date.toLocaleDateString();
                jQuery(this).text(abs);
            }
            if (!this.title)
                this.title = date.toLocaleString();
        });
};


$(document).ready(function() {
        var times = "#updating time, .atom-published time";
        $(times).prettyDate();
        setInterval(function() { $(times).prettyDate(); }, 60000);
        });

