const siteConfig = {
  gameUrl: "https://rmr.global",
  telegramUrl: "https://t.me/dykyiboss1",
};

const BOOT_MS = 4200;

function allowedUrl(value) {
  if (typeof value !== "string") return "#";
  const trimmed = value.trim();
  if (trimmed === "" || trimmed === "#") return "#";
  try {
    const url = new URL(trimmed);
    if (url.protocol === "http:" || url.protocol === "https:") return url.href;
  } catch (error) {
    return "#";
  }
  return "#";
}

function bindLink(anchor, raw) {
  const href = allowedUrl(raw);
  anchor.setAttribute("href", href);
  if (href === "#") {
    anchor.removeAttribute("target");
    anchor.removeAttribute("rel");
    anchor.addEventListener("click", (event) => {
      event.preventDefault();
    });
    return;
  }
  anchor.setAttribute("target", "_blank");
  anchor.setAttribute("rel", "noopener noreferrer");
}

function renderClock() {
  const node = document.getElementById("clock");
  const now = new Date();
  node.dateTime = now.toISOString();
  node.textContent = new Intl.DateTimeFormat("ru-RU", {
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).format(now);
}

function showCard() {
  document.documentElement.classList.add("is-ready");
  document.getElementById("splash").setAttribute("aria-hidden", "true");
  document.getElementById("card").setAttribute("aria-hidden", "false");
}

function boot() {
  const wait = BOOT_MS;
  document.documentElement.style.setProperty("--boot", wait + "ms");
  window.setTimeout(showCard, wait);
}

document.getElementById("card").setAttribute("aria-hidden", "true");
bindLink(document.getElementById("game-link"), siteConfig.gameUrl);
bindLink(document.getElementById("telegram-link"), siteConfig.telegramUrl);
renderClock();
window.setInterval(renderClock, 15000);
boot();
