
function initTerm() {
    setTimeout(function(){ 
        var term = new Terminal();
        term.open(document.getElementById('terminal'));
        term.write(' >')
    }, 150);
}