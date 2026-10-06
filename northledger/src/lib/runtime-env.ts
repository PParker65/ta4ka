type ConfigKv = {
  get(key: string): Promise<string | null>;
  put(key: string, value: string): Promise<void>;
};

type WorkerEnv = {
  SITE_CONFIG?: ConfigKv;
  ADMIN_USER?: string;
  ADMIN_PASSWORD?: string;
};

const CLOUDFLARE_CONTEXT = Symbol.for("__cloudflare-context__");

/** Bindings set by the OpenNext Cloudflare worker. Absent during `next dev`. */
export function workerEnv(): WorkerEnv | null {
  const ctx = (globalThis as Record<symbol, { env?: WorkerEnv } | undefined>)[
    CLOUDFLARE_CONTEXT
  ];
  return ctx?.env ?? null;
}
