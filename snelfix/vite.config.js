import { defineConfig } from "vite";
import { resolve } from "node:path";

export default defineConfig({
  publicDir: resolve("public"),
  build: {
    outDir: "dist",
    emptyOutDir: true,
    cssCodeSplit: false,
    modulePreload: false,
    rollupOptions: {
      input: {
        main: resolve("frontend/main.js"),
        admin: resolve("frontend/admin.js"),
      },
      output: {
        entryFileNames: "assets/[name].js",
        chunkFileNames: "assets/[name].js",
        assetFileNames: (info) => {
          if (info.name && info.name.endsWith(".css")) return "assets/site.css";
          return "assets/[name][extname]";
        },
      },
    },
  },
});
