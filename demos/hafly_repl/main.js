
function initTerm() {
    setTimeout(function(){ 
        var term = new Terminal();
        term.open(document.getElementById('terminal'));
        term.write(' >');
        term.onKey(function(x) {
            term.write(x.key);
        });
    }, 150);
}