
function initTerm() {
    setTimeout(function() { 
        var term = new Terminal({convertEol: true});
        term.open(document.getElementById('terminal'));
        term.write(' > ');
        term.onKey(function(x) {
            term.write(x.key);
        });
        term.onLineFeed(function() {
            term.write('\n > ')
        })
    }, 150);
}