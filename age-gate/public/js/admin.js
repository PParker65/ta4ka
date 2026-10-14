(function () {
  var loginView = document.getElementById("login-view");
  var appView = document.getElementById("app-view");
  var loginForm = document.getElementById("login-form");
  var loginError = document.getElementById("login-error");
  var urlForm = document.getElementById("url-form");
  var currentUrl = document.getElementById("current-url");
  var nextUrl = document.getElementById("next-url");
  var urlStatus = document.getElementById("url-status");

  function api(path, options) {
    var opts = options || {};
    opts.credentials = "same-origin";
    opts.headers = opts.headers || {};
    if (opts.body && !opts.headers["content-type"]) opts.headers["content-type"] = "application/json";
    return fetch(path, opts).then(function (res) {
      return res.json().catch(function () { return { ok: false }; }).then(function (data) {
        data.status = res.status;
        return data;
      });
    });
  }

  function showLogin() {
    loginView.hidden = false;
    appView.hidden = true;
  }

  function showApp() {
    loginView.hidden = true;
    appView.hidden = false;
    loadAll();
  }

  loginForm.addEventListener("submit", function (ev) {
    ev.preventDefault();
    loginError.textContent = "";
    var body = {
      username: loginForm.username.value,
      password: loginForm.password.value,
    };
    api("/panel/login", { method: "POST", body: JSON.stringify(body) }).then(function (data) {
      loginForm.password.value = "";
      if (!data.ok) {
        loginError.textContent = "Invalid login";
        return;
      }
      showApp();
    }).catch(function () {
      loginError.textContent = "Could not reach the server";
    });
  });

  document.getElementById("logout").addEventListener("click", function () {
    api("/panel/logout", { method: "POST", body: "{}" }).then(showLogin);
  });

  document.getElementById("refresh").addEventListener("click", loadAll);

  urlForm.addEventListener("submit", function (ev) {
    ev.preventDefault();
    saveUrl(nextUrl.value.trim());
  });

  document.getElementById("clear-url").addEventListener("click", function () {
    saveUrl("");
  });

  document.getElementById("clear-all").addEventListener("click", function () {
    if (!window.confirm("Delete every stored visit, click, and time sample?")) return;
    api("/panel/events/clear", { method: "POST", body: "{}" }).then(function (data) {
      if (data.status === 401) return showLogin();
      loadAll();
    });
  });

  function saveUrl(url) {
    urlStatus.textContent = "";
    urlStatus.className = "status";
    api("/panel/settings", { method: "POST", body: JSON.stringify({ url: url }) }).then(function (data) {
      if (data.status === 401) return showLogin();
      if (!data.ok) {
        urlStatus.textContent = data.error || "Could not save";
        urlStatus.className = "status error";
        return;
      }
      currentUrl.value = data.url || "";
      nextUrl.value = "";
      urlStatus.textContent = data.url ? "Saved" : "Cleared";
      urlStatus.className = "status ok";
    });
  }

  function loadAll() {
    api("/panel/settings").then(function (data) {
      if (data.status === 401) return showLogin();
      currentUrl.value = data.url || "";
    });
    api("/panel/stats").then(function (data) {
      if (data.status === 401) return showLogin();
      if (!data.ok) return;
      renderStats(data);
    });
  }

  function renderStats(data) {
    var t = data.totals || {};
    document.getElementById("today-label").textContent = "Today is " + (data.today || "") + " UTC.";
    document.getElementById("stat-cards").replaceChildren(
      card("Visits", t.visits),
      card("Uniques", t.uniques),
      card("Visits today", t.todayVisits),
      card("Uniques today", t.todayUniques),
      card("Clicks", t.clicks),
      card("Clicks today", t.todayClicks),
      card("Avg. time", formatDuration(t.avgTimeSec), (t.timedVisits || 0) + " timed visits"),
    );
    renderBreakdown(document.getElementById("by-country"), data.byCountry, "Country");
    renderBreakdown(document.getElementById("by-device"), data.byDevice, "Device");
    renderBreakdown(document.getElementById("by-browser"), data.byBrowser, "Browser");
    renderBreakdown(document.getElementById("by-os"), data.byOs, "OS");
    renderEvents(data.events || []);
  }

  function card(label, value, note) {
    var el = document.createElement("article");
    el.className = "stat";
    var strong = document.createElement("b");
    strong.textContent = value == null ? "0" : String(value);
    var span = document.createElement("span");
    span.textContent = note ? label + " · " + note : label;
    el.append(strong, span);
    return el;
  }

  function renderBreakdown(host, rows, label) {
    host.replaceChildren();
    if (!rows || !rows.length) {
      var empty = document.createElement("p");
      empty.className = "empty";
      empty.textContent = "No data yet.";
      host.append(empty);
      return;
    }
    var table = document.createElement("table");
    table.append(rowEl("thead", [label, "Visits", "Clicks"], "th"));
    var body = document.createElement("tbody");
    rows.forEach(function (item) {
      body.append(rowEl("tr", [item.key, item.visits, item.clicks], "td"));
    });
    table.append(body);
    host.append(table);
  }

  function renderEvents(events) {
    var host = document.getElementById("events");
    host.replaceChildren();
    if (!events.length) {
      var empty = document.createElement("p");
      empty.className = "empty";
      empty.textContent = "No events yet.";
      host.append(empty);
      return;
    }
    var wrap = document.createElement("div");
    wrap.className = "table-wrap";
    var table = document.createElement("table");
    table.append(rowEl("thead", ["Time (UTC)", "Type", "Place", "Device", "Detail", "User agent", ""], "th"));
    var body = document.createElement("tbody");
    events.forEach(function (event) {
      var tr = document.createElement("tr");
      addCell(tr, formatTime(event.ts));
      addCell(tr, event.type || "");
      addCell(tr, place(event));
      addCell(tr, [event.device, event.os, event.browser].filter(Boolean).join(" · "));
      addCell(tr, detail(event));
      var ua = document.createElement("td");
      ua.className = "ua";
      ua.textContent = event.ua || "";
      ua.title = event.ua || "";
      tr.append(ua);
      var action = document.createElement("td");
      var button = document.createElement("button");
      button.type = "button";
      button.className = "btn-ghost";
      button.textContent = "Delete";
      button.addEventListener("click", function () {
        api("/panel/events/" + encodeURIComponent(event.id), { method: "DELETE" }).then(function (data) {
          if (data.status === 401) return showLogin();
          loadAll();
        });
      });
      action.append(button);
      tr.append(action);
      body.append(tr);
    });
    table.append(body);
    wrap.append(table);
    host.append(wrap);
  }

  function place(event) {
    return [event.city, event.region, event.country || "Unknown"].filter(Boolean).join(", ");
  }

  function detail(event) {
    if (event.type === "click") {
      var where = event.x == null ? "" : " @ " + event.x + "," + event.y;
      return "18+ button" + where + (event.viewport ? " · " + event.viewport : "");
    }
    var bits = [event.path || "/", event.lang || "", event.viewport || "", formatDuration(event.duration)];
    if (event.referrer) bits.push(event.referrer);
    if (event.locale) bits.push(event.locale);
    return bits.filter(Boolean).join(" · ");
  }

  function rowEl(tag, cells, cellTag) {
    var tr = document.createElement(tag === "thead" ? "tr" : tag);
    if (tag === "thead") {
      var head = document.createElement("thead");
      cells.forEach(function (text) {
        var cell = document.createElement(cellTag);
        cell.textContent = text;
        tr.append(cell);
      });
      head.append(tr);
      return head;
    }
    cells.forEach(function (text) {
      var cell = document.createElement(cellTag);
      cell.textContent = text == null ? "" : String(text);
      tr.append(cell);
    });
    return tr;
  }

  function addCell(tr, text) {
    var td = document.createElement("td");
    td.textContent = text == null ? "" : String(text);
    tr.append(td);
  }

  function formatTime(ts) {
    if (!ts) return "";
    return new Date(ts).toISOString().replace("T", " ").slice(0, 19);
  }

  function formatDuration(seconds) {
    var n = Number(seconds) || 0;
    if (n < 60) return n + "s";
    var m = Math.floor(n / 60);
    var s = n % 60;
    return m + "m " + s + "s";
  }

  api("/panel/session").then(function (data) {
    if (data.ok) showApp();
  });
})();
