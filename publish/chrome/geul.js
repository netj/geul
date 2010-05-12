/*
 * Javascript Vocabularies for Geul
 * Author: Jaeho Shin <netj@sparcs.org>
 * Created: 2009-09-08
 */

var BaseURI = document.baseURI || /* for IE */ document.getElementsByTagName("base").item(0).href;
var PermaLink;

var NextGeul;
var CurrentGeul;
var PreviousGeul;

var AtomNS = "http://www.w3.org/2005/Atom";
function getGeulIndexFor(indexId, asyncTask) {
    var xmlhttp;
    // branch for native XMLHttpRequest object
    if(window.XMLHttpRequest && !(window.ActiveXObject)) {
        try {
            xmlhttp = new XMLHttpRequest();
        } catch(e) {
            xmlhttp = null;
        }
        // branch for IE/Windows ActiveX version
    } else if(window.ActiveXObject) {
        try {
            xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
        } catch(e) {
            try {
                xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
            } catch(e) {
                xmlhttp = null;
            }
        }
    }
    if (! xmlhttp) {
        alert("Your browser does not support Ajax!");
        return;
    }
    xmlhttp.onreadystatechange = function() {
        if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
            var index;
            try {
                var atom;
                if (window.ActiveXObject) { 
                    // Hack for IE
                    // See: http://groups.google.com/group/rubyonrails-spinoffs/browse_thread/thread/621a6ddf13252b93?pli=1
                    var atom = new ActiveXObject("Msxml2.DOMDocument"); 
                    atom.loadXML(xmlhttp.responseText); 
                } else {
                    atom = xmlhttp.responseXML;
                }
                var entry = atom.getElementsByTagName("entry");
                index = [];
                for (var i=0; i<entry.length; i++) {
                    var o = {};
                    function firstNodeValue(name) {
                        try {
                            var e;
                            if (window.ActiveXObject)
                                e = entry.item(i);
                            else
                                e = entry[i];
                            return e.getElementsByTagName(name)[0].firstChild.nodeValue;
                        } catch (e) {
                        }
                        return null;
                    }
                    o.id        = firstNodeValue(       "id");
                    o.title     = firstNodeValue(    "title");
                    o.published = firstNodeValue("published");
                    index.push(o);
                }
            } catch (e) {
                // console.log(e.name + ": " + e.message);
                return;
            }
            asyncTask(index);
        }
    }
    var indexUrl = BaseURI + indexId + "/index.atom";
    xmlhttp.open("GET", indexUrl, true);
    xmlhttp.send(null);
}

function getNeighborArticlesFor(asyncTask) {
    PermaLink = document.getElementsByName("PermaLink")[0].content;
    var geulId = PermaLink.substring(BaseURI.length);
    var indexId = parseInt(geulId.replace(/\/.*$/, ''));
    if (isNaN(indexId))
        return;
    getGeulIndexFor(indexId, function(index) {
            // index is ordered reverse chronologically
            for (var i=0; i<index.length; i++) {
                if (index[i].id == PermaLink) {
                    CurrentGeul = index[i];
                    if (i > 0)
                        NextGeul = index[i-1];
                    else
                        getGeulIndexFor(indexId+1, function(nextIndex) {
                                NextGeul = nextIndex[nextIndex.length-1];
                                asyncTask(NextGeul, PreviousGeul);
                            });
                    if (i+1 < index.length)
                        PreviousGeul = index[i+1];
                    else
                        getGeulIndexFor(indexId-1, function(previousIndex) {
                                PreviousGeul = previousIndex[0];
                                asyncTask(NextGeul, PreviousGeul);
                            });
                    asyncTask(NextGeul, PreviousGeul);
                    break;
                }
            }
        });
}
