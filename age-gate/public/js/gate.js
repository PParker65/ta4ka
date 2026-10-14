(function () {
  var btn = document.getElementById("age-btn");
  var visitId = document.body.getAttribute("data-visit") || "";
  var started = Date.now();

  function viewport() {
    return window.innerWidth + "x" + window.innerHeight;
  }

  function payload(extra) {
    var data = {
      visitId: visitId,
      viewport: viewport(),
      locale: navigator.language || "",
      lang: document.documentElement.lang || "",
      referrer: document.referrer || "",
      path: location.pathname + location.search,
    };
    if (extra) {
      for (var key in extra) data[key] = extra[key];
    }
    return data;
  }

  function send(url, data, beacon) {
    var body = JSON.stringify(data);
    if (beacon && navigator.sendBeacon) {
      var blob = new Blob([body], { type: "application/json" });
      return navigator.sendBeacon(url, blob);
    }
    return fetch(url, {
      method: "POST",
      headers: { "content-type": "application/json" },
      credentials: "same-origin",
      keepalive: true,
      body: body,
    });
  }

  send("/panel/hit", payload());

  function sendTime(beacon) {
    var duration = Math.round((Date.now() - started) / 1000);
    send("/panel/time", payload({ duration: duration }), beacon);
  }

  setInterval(function () {
    sendTime(false);
  }, 15000);
  document.addEventListener("visibilitychange", function () {
    if (document.visibilityState === "hidden") sendTime(true);
  });
  window.addEventListener("pagehide", function () {
    sendTime(true);
  });

  if (!btn) return;
  btn.addEventListener("click", function (ev) {
    if (btn.disabled) return;
    btn.disabled = true;
    fetch("/panel/click", {
      method: "POST",
      headers: { "content-type": "application/json" },
      credentials: "same-origin",
      body: JSON.stringify(
        payload({
          control: "age18",
          x: ev.clientX,
          y: ev.clientY,
        }),
      ),
    })
      .then(function (res) {
        return res.json();
      })
      .then(function (data) {
        if (data && data.url) {
          location.assign(data.url);
          return;
        }
        btn.disabled = false;
      })
      .catch(function () {
        btn.disabled = false;
      });
  });
})();
