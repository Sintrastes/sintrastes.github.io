function initTerm(callback) {
    setTimeout(function() { 
        var term = new Terminal({convertEol: true});
        var currentText = '';
        term.open(document.getElementById('terminal'));
        term.write(' > ');
        term.onKey(function(x) {
            if (x.key == '\r') {
                callback(currentText, function(processedText) {
                    term.write('\r\n');
                    term.write(processedText);
                    term.write('\r\n > ');
                    currentText = '';
                });
            } else if (x.key.charCodeAt(0) == 127) {
                if (currentText.length > 0) {
                    term.write("\b \b");
                    currentText = currentText.substring(0, currentText.length - 1);
                }
            } else {
                term.write(x.key);
                currentText += x.key;
            }
            console.log(x);
        });
    }, 150);
}