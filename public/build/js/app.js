var isSD = !0,
    Site = "sherpadesk.com/",
    MobileSite = "https://m.sherpadesk.com/";
var ApiSite = "https://api." + Site,
    vtimer = null,
    t1 = 1;

function check() {
    var a = document.getElementsByTagName("ion-app1");
    a && a[0] && location.reload()
}

function downloadJSAtOnload() {
    var viewport = document.querySelector("meta[name=viewport]");
    viewport.setAttribute('content', 'viewport-fit=cover, width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no, minimal-ui'); /*if ("true"==localStorage.getItem("isAndroid")) document.getElementsByTagName("ion-app")[0].setAttribute("style", "top: 30px;height: 90%");*/
    if ("function" != typeof require || !require) {
        var a = document.createElement("script");
        a.src = "build/js/vendor.bundle.js";
        document.body.appendChild(a)
    }
    setTimeout(check, "true" == localStorage.isPhonegap ? 4E4 : 15E3);
    var b = document.getElementsByTagName("ion-app1");
    "true" != localStorage.isPhonegap || "true" != localStorage.isIos && "true" != localStorage.isIosStatus || (a = document.createElement("style"), a.type = "text/css", a.styleSheet ? a.styleSheet.cssText = "ion-app1 scroll-content {padding-top: 36px  !important;} ion-app1 ion-navbar {top: 20px  !important;} " :
        a.appendChild(document.createTextNode("ion-app1 scroll-content {padding-top: 36px  !important;} ion-app1 ion-navbar {top: 20px  !important;} ")), document.getElementsByTagName("head")[0].appendChild(a));
    var c = "";
    if (!localStorage.current || 56 > localStorage.current.indexOf('"instance"') - localStorage.current.indexOf('"key"')) localStorage.dash_cache = "";
    else {
        c = '<img id=preload class=Absolute-Center src=img/loading2.gif alt="Loading...">';
        a = new XMLHttpRequest;
        a.open("GET", ApiSite + "ping", !0);
        var d = JSON.parse(localStorage.getItem("current") ||
            "null") || {};
        a.setRequestHeader("Authorization", "Basic " + btoa(d.org + "-" + d.inst + ":" + d.key));
        a.send()
    }
    var e = localStorage.dash_cache || '<ion-loading role="dialog" class="loading-cmp"><div class="backdrop" disable-activated="" role="presentation"></div><div class="loading-wrapper loading-wrapper1" style="opacity: 1;  transform: scale(1);"><div class="loading-spinner"><img src="img/loading2.gif"></div><div class="loading-content">Loading Your Profile...</div></div></ion-loading><ion-nav id="nav" swipe-back-enabled="false" class="menu-content menu-content-reveal has-views" style="touch-action: pan-y; -webkit-user-select: none; -webkit-user-drag: none; -webkit-tap-highlight-color: rgba(0, 0, 0, 0); transform: translateX(0px);"><div></div><ion-page _ngcontent-tcs-14="" class="login-page show-page" style="z-index: 99;"><ion-content class="login" padding=""><scroll-content><div class="list max-width"><a title="Support Portal" href="https://support.sherpadesk.com/portal/"><img class="imglogo img-padding" src="img/logo.png"></a><form novalidate=""><div class="tooltips"><input disabled class="width100 blue3 subject-create commentText ng-untouched ng-pristine ng-valid" ngcontrol="email" pattern="^[^@s]+@[^@s]+(.[^@s]+)+$" placeholder="email" required="" type="email"> \x3c!--template bindings={}--\x3e</div><br><div class="tooltips"><input disabled class="width100 blue3 subject-create commentText ng-untouched ng-dirty ng-valid" ngcontrol="password" placeholder="password" required="" type="password"> \x3c!--template bindings={}--\x3e</div><br><button block="" class="login-margin disable-hover button button-default button-block button-secondary" secondary="" type="submit"><span class="button-inner">Login</span><ion-button-effect></ion-button-effect></button><br></scroll-content></ion-content></ion-page><div nav-portal=""></div></ion-nav>';
    "true" === localStorage.getItem("isPhonegap") && "file:" !== window.location.protocol && "localhost" !== window.location.hostname && (a = document.createElement("script"), a.src = MobileSite + ("true" == localStorage.getItem("isAndroid") || navigator.userAgent.match(/(Android)/) ? "build/js/android/cordovan.js" : ""), document.body.appendChild(a));
    if ("true" === localStorage.getItem("isPhonegap") || "function" !== typeof Map) a = document.createElement("script"), a.src = "build/js/es6-shim.min.js", document.body.appendChild(a);
    a = document.createElement("script");
    a.src = "build/js/shims_for_IE.js";
    document.body.appendChild(a);
    a = document.createElement("script");
    a.src = "build/js/Reflect.js";
    document.body.appendChild(a);
    a = document.createElement("script");
    a.src = "build/js/zone.min.js";
    document.body.appendChild(a);
    a = document.createElement("link");
    a.href = "true" == localStorage.getItem("isAndroid") || navigator.userAgent.match(/(Android)/) ? "build/css/app.md.css" : "build/css/app.ios.css";
    a.rel = "stylesheet";
    document.body.appendChild(a);
    a =
        document.createElement("link");
    a.href = MobileSite + "build/css/my.css?v=" + (localStorage.version || "");
    a.rel = "stylesheet";
    document.body.appendChild(a);
    setTimeout(function() {
        var a = document.createElement("script");
        a.src = "build/js/app.bundle.js?v=" + (localStorage.version || "");
        //a.src = MobileSite + "build/js/app.bundle.js?v=" + (localStorage.version || "");
        document.body.appendChild(a)
    }, 200);
    a = null;
    b && b[0] && e && setTimeout(function() {
        b[0].innerHTML = c + e;
        c = e = b = null
    }, 500)
}
window.addEventListener ? window.addEventListener("load", downloadJSAtOnload, !1) : window.attachEvent ? window.attachEvent("onload", downloadJSAtOnload) : window.onload = downloadJSAtOnload;

function detectIE() {
    var a = window.navigator.userAgent,
        b = a.indexOf("MSIE ");
    if (0 < b) return parseInt(a.substring(b + 5, a.indexOf(".", b)), 10);
    if (0 < a.indexOf("Trident/")) return b = a.indexOf("rv:"), parseInt(a.substring(b + 3, a.indexOf(".", b)), 10);
    b = a.indexOf("Edge/");
    return 0 < b ? parseInt(a.substring(b + 5, a.indexOf(".", b)), 10) : !1
}
if (detectIE) {
    if (!("classList" in document.createElementNS("http://www.w3.org/2000/svg", "g"))) {
        var descr = Object.getOwnPropertyDescriptor(HTMLElement.prototype, "classList");
        Object.defineProperty(SVGElement.prototype, "classList", descr)
    }
    Element.prototype.remove = function() {
        this.parentElement.removeChild(this)
    };
    NodeList.prototype.remove = HTMLCollection.prototype.remove = function() {
        for (var a = this.length - 1; 0 <= a; a--) this[a] && this[a].parentElement && this[a].parentElement.removeChild(this[a])
    }
}
var img1 = new Image;
img1.src = "img/close.png";
var img2 = new Image;
img2.src = "img/loading2.gif";
window.onbeforeunload = function(a) {
    window.dash && localStorage.setItem("dash_cache", window.dash || "")
};

function handleOpenURL(a) {
    if (a) {
        var b = a.substring(13);
        b = b.split(":");
        a = {};
        a[b[0]] = b[1];
        b = document.createEvent("CustomEvent");
        b.initCustomEvent("handle", !1, !1, a);
        document.dispatchEvent(b)
    }
}
var _gaq = _gaq || [];

function googleTag() {
    _gaq.push(["_setAccount", "UA-998328-15"]);
    _gaq.push(["_trackPageview"]);
    var a = document.createElement("script");
    a.type = "text/javascript";
    a.async = !0;
    a.src = ("https:" == document.location.protocol ? "https://ssl" : "http://www") + ".google-analytics.com/ga.js";
    var b = document.getElementsByTagName("script")[0];
    b.parentNode.insertBefore(a, b)
}
setTimeout(googleTag, 3E4);

function googleConversion() {
    var a = new Image,
        b = document.getElementsByTagName("body")[0];
    a.onload = function() {
        b.appendChild(a)
    };
    a.src = "http://www.googleadservices.com/pagead/conversion/1040470683/?value=1.00&currency_code=USD&label=KRf-CIfZrQQQm6WR8AM&guid=ON&script=0"
}
setTimeout(googleConversion, 3E4);