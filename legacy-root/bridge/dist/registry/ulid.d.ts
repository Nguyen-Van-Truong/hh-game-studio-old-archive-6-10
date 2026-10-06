/** Crockford Base32 ULID (26 chars). Format check plus CSPRNG mint. */
export declare const EXAMPLE_ULID = "01ARZ3NDEKTSV4RRFFQ69G5FAV";
export declare function isUlid(value: string): boolean;
export declare function newUlid(nowMs?: number): string;
