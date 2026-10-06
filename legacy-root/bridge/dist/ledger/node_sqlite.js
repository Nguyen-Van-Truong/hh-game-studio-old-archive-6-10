import { createRequire } from "node:module";
/** Node 24 built-in SQLite. No npm driver. */
export function openSqliteFile(filePath) {
    const require = createRequire(import.meta.url);
    const sqlite = require("node:sqlite");
    return new sqlite.DatabaseSync(filePath);
}
