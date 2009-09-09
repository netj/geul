/*
 * Javascript Vocabularies for Geul
 * Author: Jaeho Shin <netj@sparcs.org>
 * Created: 2009-09-08
 */

var BaseURI = document.baseURI || /* for IE */ document.getElementsByTagName("base").item(0).href;
var PermaLink;
var GeulID;

var NextGeul;
var CurrentGeul;
var PreviousGeul;

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
                index = eval(xmlhttp.responseText);
            } catch (e) {
                //alert(e.name + ": " + e.message);
                return;
            }
            asyncTask(index);
        }
    }
    var indexUrl = BaseURI + indexId + "/index.json";
    xmlhttp.open("GET", indexUrl, true);
    xmlhttp.send(null);
}

function getNeighborArticlesFor(asyncTask) {
    PermaLink = document.getElementsByName("PermaLink")[0].content;
    GeulID = PermaLink.substring(BaseURI.length);
    var indexId = parseInt(GeulID.replace(/\/.*$/, ''));
    if (isNaN(indexId))
        return;
    getGeulIndexFor(indexId, function(index) {
            // index is ordered reverse chronologically
            for (var i=0; i<index.length; i++) {
                if (index[i].id == GeulID) {
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
