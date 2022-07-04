
function initTerm() {
    setTimeout(function() { 
        var term = new Terminal({convertEol: true});
        term.open(document.getElementById('terminal'));
        term.write(' > ');
        term.onKey(function(x) {
            if (x != '\n') {
                term.write(x.key);
            } else {
                term.write('\r\n > ');
            }
        });
    }, 150);
}