/** Crockford Base32 ULID (26 chars). Format check plus CSPRNG mint. */
export declare function isUlid(value: string): boolean;
export declare function newUlid(nowMs?: number): string;
export declare function parseUlid(value: string, path: string): string;
