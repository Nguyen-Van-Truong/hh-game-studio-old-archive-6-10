/** One project writer + per-file/scene leases with TTL and hash drift detection. */
export declare const DEFAULT_LEASE_TTL_MS = 30000;
export interface WriterLock {
    writer_id: string;
    expires_at: number;
    pid: number;
}
export interface FileLease {
    writer_id: string;
    hash: string;
    expires_at: number;
    rel: string;
    pid: number;
    heartbeat_at: number;
}
export interface LeaseTableOptions {
    /** Relative dir under project root. Default `.hh-agent` (R2-WP5). */
    dir?: string;
}
export declare function contentHash(absPath: string): string;
export declare class LeaseTable {
    readonly projectRoot: string;
    readonly writerPath: string;
    readonly filesPath: string;
    constructor(projectRoot: string, opts?: LeaseTableOptions);
    private withFilesLock;
    private readWriter;
    private readFiles;
    acquireWriter(writerId: string, ttlMs?: number): WriterLock;
    acquireFile(writerId: string, rel: string, abs: string, ttlMs?: number, opts?: {
        allowHashRefresh?: boolean;
        skipWriter?: boolean;
    }): FileLease;
    heartbeat(writerId: string, rel: string, ttlMs?: number): FileLease;
    releaseFile(writerId: string, rel: string): void;
    releaseWriter(writerId: string): void;
    assertUnchanged(rel: string, abs: string): void;
    peekWriter(): WriterLock | undefined;
    peekFile(rel: string): FileLease | undefined;
    noteWritten(writerId: string, rel: string, abs: string, ttlMs?: number): FileLease;
}
