import { promises as fs } from "fs";
import path from "path";
import { unstable_noStore as noStore } from "next/cache";
import { workerEnv } from "./runtime-env";

export type SiteStats = {
  visits: number;
  clicks: number;
  updatedAt: string | null;
};

const EMPTY_STATS: SiteStats = { visits: 0, clicks: 0, updatedAt: null };
const statsPath = path.join(process.cwd(), "data", "site-stats.json");
const KV_KEY = "site-stats";

let writeChain: Promise<void> = Promise.resolve();

function parseStats(raw: string): SiteStats | null {
  try {
    const value: unknown = JSON.parse(raw);
    if (typeof value !== "object" || value === null) return null;
    const record = value as Record<string, unknown>;
    const visits = record.visits;
    const clicks = record.clicks;
    if (typeof visits !== "number" || !Number.isInteger(visits) || visits < 0) return null;
    if (typeof clicks !== "number" || !Number.isInteger(clicks) || clicks < 0) return null;
    const updatedAt = typeof record.updatedAt === "string" ? record.updatedAt : null;
    return { visits, clicks, updatedAt };
  } catch {
    return null;
  }
}

export async function readStats(): Promise<SiteStats> {
  noStore();
  const kv = workerEnv()?.SITE_CONFIG;
  if (kv) {
    const raw = await kv.get(KV_KEY);
    if (!raw) return EMPTY_STATS;
    return parseStats(raw) ?? EMPTY_STATS;
  }

  try {
    const raw = await fs.readFile(statsPath, "utf8");
    return parseStats(raw) ?? EMPTY_STATS;
  } catch {
    return EMPTY_STATS;
  }
}

async function writeStats(stats: SiteStats): Promise<void> {
  const body = `${JSON.stringify(stats, null, 2)}\n`;
  const kv = workerEnv()?.SITE_CONFIG;
  if (kv) {
    await kv.put(KV_KEY, body);
    return;
  }

  await fs.mkdir(path.dirname(statsPath), { recursive: true });
  const tempPath = `${statsPath}.tmp`;
  await fs.writeFile(tempPath, body, "utf8");
  await fs.rename(tempPath, statsPath);
}

export function incrementStat(field: "visits" | "clicks"): Promise<void> {
  const run = writeChain.then(async () => {
    const current = await readStats();
    await writeStats({
      visits: current.visits + (field === "visits" ? 1 : 0),
      clicks: current.clicks + (field === "clicks" ? 1 : 0),
      updatedAt: new Date().toISOString(),
    });
  });
  writeChain = run.catch(() => undefined);
  return run;
}
