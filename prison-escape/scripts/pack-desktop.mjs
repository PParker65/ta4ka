import { cpSync, mkdirSync, rmSync, chmodSync, existsSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const dist = join(root, 'dist');
const outName = 'SIZO-Hatka';
const staging = join(root, '.desktop-pack', outName);
const zipOut = join('/opt/cursor/artifacts', `${outName}.zip`);
const localZip = join(root, '.desktop-pack', `${outName}.zip`);

if (!existsSync(dist)) {
  console.error('dist/ missing — run npm run build:desktop first');
  process.exit(1);
}

rmSync(join(root, '.desktop-pack'), { recursive: true, force: true });
mkdirSync(staging, { recursive: true });
cpSync(dist, staging, { recursive: true });
cpSync(join(root, 'desktop', 'START.command'), join(staging, 'START.command'));
cpSync(join(root, 'desktop', 'START.bat'), join(staging, 'START.bat'));
cpSync(join(root, 'desktop', 'README.txt'), join(staging, 'README.txt'));
chmodSync(join(staging, 'START.command'), 0o755);

mkdirSync('/opt/cursor/artifacts', { recursive: true });
execSync(`cd "${join(root, '.desktop-pack')}" && zip -r "${localZip}" "${outName}"`, { stdio: 'inherit' });
cpSync(localZip, zipOut);
writeFileSync(
  join('/opt/cursor/artifacts', `${outName}-HOW-TO.txt`),
  `Скачай ${outName}.zip → распакуй на Рабочий стол → двойной клик START.command (Mac) или START.bat (Windows).\n`,
);
console.log('packed', zipOut);
