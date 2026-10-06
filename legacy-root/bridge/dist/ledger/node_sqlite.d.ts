export type SqlValue = null | number | bigint | string | Uint8Array;
export interface SqliteStatement {
    run(...params: SqlValue[]): {
        changes: number;
    };
    get(...params: SqlValue[]): unknown;
    all(...params: SqlValue[]): unknown[];
}
export interface SqliteDatabase {
    exec(sql: string): void;
    prepare(sql: string): SqliteStatement;
    close(): void;
}
/** Node 24 built-in SQLite. No npm driver. */
export declare function openSqliteFile(filePath: string): SqliteDatabase;
