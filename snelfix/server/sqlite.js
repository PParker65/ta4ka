import { DatabaseSync } from "node:sqlite";

export function openSqlite(file) {
  const db = new DatabaseSync(file);
  db.exec("PRAGMA journal_mode = WAL");
  db.exec("PRAGMA foreign_keys = ON");
  return {
    exec(sql) {
      db.exec(sql);
    },
    prepare(sql) {
      const run = (params) => ({
        async all() {
          return { results: db.prepare(sql).all(...params) };
        },
        async first() {
          return db.prepare(sql).get(...params) ?? null;
        },
        async run() {
          const info = db.prepare(sql).run(...params);
          return {
            success: true,
            meta: {
              changes: Number(info.changes || 0),
              last_rowid: Number(info.lastInsertRowid || 0),
            },
          };
        },
      });
      return {
        bind(...params) {
          return run(params);
        },
        all() {
          return run([]).all();
        },
        first() {
          return run([]).first();
        },
        run() {
          return run([]).run();
        },
      };
    },
  };
}
