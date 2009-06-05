/* 붓 JavaScript
 * Author: Jaeho Shin <netj@sparcs.kaist.ac.kr>
 * Created: 2004-08-30
 */

function go_today() {
    var d = new Date();
    var y = d.getYear(), m = d.getMonth() + 1;
    location = '/' + (y < 2000 ? y + 1900 : y)
        + '/' + (m < 10 ? '0' + m : m) + '/';
}

function go_search() {
    var search = document.getElementById("search");
    search.style.display = 'block';
    window.scrollTo(search.offsetLeft, search.offsetTop);
    search.elements["q"].focus();
}

// TODO: fill personal info for comment form from cookie


function xbel_open_folder(f) {
    f.className = 'xbel-folder-opened';
}
function xbel_close_folder(f) {
    f.className = 'xbel-folder';
}

