import { promises as fs } from "fs";
import path from "path";
import { unstable_noStore as noStore } from "next/cache";
import { DEFAULT_CONFIG } from "./defaults";
import { workerEnv } from "./runtime-env";
import type { SiteConfig } from "./types";
import { validateConfig } from "./validate";

const configPath = path.join(process.cwd(), "data", "site-config.json");
const KV_KEY = "site-config";

function parseStored(raw: string): SiteConfig | null {
  try {
    const result = validateConfig(JSON.parse(raw));
    return result.ok ? result.config : null;
  } catch {
    return null;
  }
}

export async function readConfig(): Promise<SiteConfig> {
  noStore();
  const kv = workerEnv()?.SITE_CONFIG;
  if (kv) {
    const raw = await kv.get(KV_KEY);
    if (raw) {
      const parsed = parseStored(raw);
      if (parsed) return parsed;
    }
    return DEFAULT_CONFIG;
  }

  try {
    const raw = await fs.readFile(configPath, "utf8");
    return parseStored(raw) ?? DEFAULT_CONFIG;
  } catch {
    return DEFAULT_CONFIG;
  }
}

export async function writeConfig(config: SiteConfig): Promise<void> {
  const body = `${JSON.stringify(config, null, 2)}\n`;
  const kv = workerEnv()?.SITE_CONFIG;
  if (kv) {
    await kv.put(KV_KEY, body);
    return;
  }

  await fs.mkdir(path.dirname(configPath), { recursive: true });
  const tempPath = `${configPath}.tmp`;
  await fs.writeFile(tempPath, body, "utf8");
  await fs.rename(tempPath, configPath);
}
