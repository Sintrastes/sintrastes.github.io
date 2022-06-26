function download(text, name, type) {
    var a = document.createElement("a");
    var file = new Blob([text], {type: type});
    a.href = URL.createObjectURL(file);
    a.download = name;
    a.click();
    setTimeout(function() {
        document.body.removeChild(a);
    }, 0);
}

function setCookie(cname, cvalue, exdays) {
    console.log("setCookie 1");
    const d = new Date();
    console.log("setCookie 1");
    d.setTime(d.getTime() + (exdays*24*60*60*1000));
    console.log("setCookie 1");
    let expires = "expires="+ d.toUTCString();
    console.log("setCookie 1");
    document.cookie = cname + "=" + cvalue + ";" + expires + ";path=/";
    console.log("setCookie 1");
}

function getCookie(cname) {
    console.log("setCookie 1");
    let name = cname + "=";
    console.log("setCookie 2");
    let decodedCookie = decodeURIComponent(document.cookie);
    console.log("setCookie 3");
    let ca = decodedCookie.split(';');
    console.log("setCookie 4");
    for(let i = 0; i <ca.length; i++) {
      console.log("setCookie loop 1");
      let c = ca[i];
      console.log("setCookie loop 2");
      while (c.charAt(0) == ' ') {
        console.log("setCookie loop 3");
        c = c.substring(1);
      }
      if (c.indexOf(name) == 0) {
        console.log("setCookie loop 4");
        return c.substring(name.length, c.length);
      }
    }
    console.log("setCookie 5");
    return "";
}