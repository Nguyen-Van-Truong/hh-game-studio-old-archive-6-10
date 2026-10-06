/** Process and network allowlist. No arbitrary shell; argv arrays only. */
export declare const PROCESS_ALLOWLIST: readonly ["godot", "gut", "exporter", "git", "icacls"];
export declare function canonicalizeProcessName(file: string): string;
export declare function assertAgentProcess(file: string, _argv: readonly string[], opts?: {
    shell?: boolean;
}): void;
export declare function assertLoopbackHost(host: string): void;
export declare function isShellSpawnForbidden(opts: {
    shell?: unknown;
} | undefined): boolean;
