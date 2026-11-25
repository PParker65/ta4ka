import { copyFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  base: process.env.BASE_PATH || '/',
  plugins: [
    tailwindcss(),
    {
      name: 'spa-404',
      closeBundle() {
        copyFileSync(resolve('dist/index.html'), resolve('dist/404.html'));
      },
    },
  ],
  server: {
    host: true,
    port: 5173,
    strictPort: true,
  },
  preview: {
    host: true,
    port: 4173,
  },
  build: {
    target: 'es2020',
    sourcemap: false,
  },
});
