import { promises as fs } from "fs";
import path from "path";
import { unstable_noStore as noStore } from "next/cache";
import { DEFAULT_CONFIG } from "./defaults";
import type { SiteConfig } from "./types";
import { validateConfig } from "./validate";

const configPath = path.join(process.cwd(), "data", "site-config.json");

export async function readConfig(): Promise<SiteConfig> {
  noStore();
  try {
    const raw = await fs.readFile(configPath, "utf8");
    const result = validateConfig(JSON.parse(raw));
    if (result.ok) return result.config;
  } catch {
    // A missing or unreadable file falls back to the shipped defaults.
  }
  return DEFAULT_CONFIG;
}

export async function writeConfig(config: SiteConfig): Promise<void> {
  await fs.mkdir(path.dirname(configPath), { recursive: true });
  const tempPath = `${configPath}.tmp`;
  await fs.writeFile(tempPath, `${JSON.stringify(config, null, 2)}\n`, "utf8");
  await fs.rename(tempPath, configPath);
}
