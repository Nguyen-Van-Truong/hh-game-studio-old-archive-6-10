/** 256-bit session secret from CSPRNG. Hex, 64 chars. */
export declare function generateSessionToken(): string;
export declare function isSessionToken(value: string): boolean;
export declare function tokensEqual(left: string, right: string): boolean;
export declare function redactSecrets(text: string, secrets: readonly string[]): string;
