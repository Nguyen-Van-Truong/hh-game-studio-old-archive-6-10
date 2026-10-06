/** Exponential backoff for plugin reconnects. Deterministic; no PRNG jitter. */
export declare function backoffMs(attempt: number, baseMs: number, capMs: number): number;
