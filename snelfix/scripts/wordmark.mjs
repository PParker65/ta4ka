import { existsSync, readFileSync, writeFileSync } from "node:fs";

const fontPath = "node_modules/@fontsource/barlow-condensed/files/barlow-condensed-latin-600-normal.woff2";
if (!existsSync(fontPath)) {
  console.warn("wordmark font not installed yet");
  process.exit(0);
}
const b64 = readFileSync(fontPath).toString("base64");
const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 132" role="img" aria-labelledby="title">
  <title id="title">SnelFix Auto</title>
  <style>
    @font-face {
      font-family: "SnelFix Wordmark";
      src: url("data:font/woff2;base64,${b64}") format("woff2");
      font-weight: 600;
      font-style: normal;
    }
    .name { font-family: "SnelFix Wordmark", "Arial Narrow", Impact, sans-serif; font-weight: 600; }
  </style>
  <text class="name" x="0" y="78" fill="#f4f1ea" font-size="92" letter-spacing="-1.5">SNELFIX</text>
  <rect x="0" y="96" width="86" height="7" fill="#b6ff3c"/>
  <text class="name" x="98" y="108" fill="#b6ff3c" font-size="22" letter-spacing="6">AUTO</text>
</svg>
`;
writeFileSync("public/brand/wordmark.svg", svg);
console.log("wordmark written");
