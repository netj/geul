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
    if (window.XMLHttpRequest) {
        // code for IE7+, Firefox, Chrome, Opera, Safari
        xmlhttp = new XMLHttpRequest();
    } else if (window.ActiveXObject) {
        // code for IE6, IE5
        xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
    } else {
        alert("Your browser does not support XMLHTTP!");
    }
    xmlhttp.onreadystatechange = function() {
        if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
            var index;
            try {
                var entry = xmlhttp.responseXML.getElementsByTagName("entry");
                index = [];
                for (var i=0; i<entry.length; i++) {
                    var o = {};
                    function firstNodeValue(name) {
                        try {
                            return entry[i].getElementsByTagName(name)[0].firstChild.nodeValue;
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
                console.log(e.name + ": " + e.message);
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
