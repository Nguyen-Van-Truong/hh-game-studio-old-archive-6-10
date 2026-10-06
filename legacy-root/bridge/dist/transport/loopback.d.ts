import type net from "node:net";
export declare const LOOPBACK_HOST: "127.0.0.1";
export declare const OS_ASSIGNED_PORT: 0;
export type ListenFn = (opts: net.ListenOptions, cb: () => void) => net.Server;
export interface ListenDeps {
    listen?: ListenFn;
}
export declare function loopbackListenOptions(): net.ListenOptions;
export declare function assertLoopbackHost(host: string): void;
export declare function assertOsAssignedPort(port: number): void;
/**
 * Bind an existing net.Server to 127.0.0.1 with an OS-assigned port.
 * EADDRINUSE retries the same listen options (not a port walk).
 */
export declare function listenLoopback(server: net.Server, deps?: ListenDeps): Promise<{
    host: typeof LOOPBACK_HOST;
    port: number;
}>;
/** Test/doctor hook: reject before any listen when the caller names a non-loopback host. */
export declare function listenExplicit(server: net.Server, host: string, port: number, deps?: ListenDeps): Promise<{
    host: typeof LOOPBACK_HOST;
    port: number;
}>;
