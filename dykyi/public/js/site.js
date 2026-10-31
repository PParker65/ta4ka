const siteConfig = {
  gameUrl: "#",
  telegramUrl: "#",
};

const BOOT_MS = 4200;
const LINE_MS = 1500;
const lines = ["Шконка остыла.", "Лента уже тёплая."];

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
  anchor.addEventListener("click", (event) => {
    if (anchor.getAttribute("href") === "#") event.preventDefault();
  });
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
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const wait = BOOT_MS;
  document.documentElement.style.setProperty("--boot", wait + "ms");
  const line = document.getElementById("splash-line");

  if (!reduce) {
    let step = 0;
    const timer = window.setInterval(() => {
      step += 1;
      if (step >= lines.length) {
        window.clearInterval(timer);
        return;
      }
      line.textContent = lines[step];
      line.classList.remove("is-in");
      void line.offsetWidth;
      line.classList.add("is-in");
    }, LINE_MS);
  }

  window.setTimeout(showCard, wait);
}

document.getElementById("card").setAttribute("aria-hidden", "true");
bindLink(document.getElementById("game-link"), siteConfig.gameUrl);
bindLink(document.getElementById("telegram-link"), siteConfig.telegramUrl);
renderClock();
window.setInterval(renderClock, 15000);
boot();
