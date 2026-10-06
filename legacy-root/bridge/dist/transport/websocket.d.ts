import type { SessionLog } from "../session/log.js";
import { type PluginCommandResult, type PluginReadbackResult } from "./plugin_rpc.js";
export interface PluginTransport {
    host: "127.0.0.1";
    port: number;
    close: () => Promise<void>;
    pluginConnected: () => boolean;
    dispatchToPlugin: (envelope: Record<string, unknown>, timeoutMs: number) => Promise<PluginCommandResult>;
    readPostcondition: (commandId: string, timeoutMs: number) => Promise<PluginReadbackResult>;
    dropPlugin: () => void;
    sendControl: (msg: Record<string, unknown>) => boolean;
}
export interface PluginTransportOpts {
    protocol: string;
    projectId: string;
    token: string;
    sessionId: string;
    log: SessionLog;
    heartbeatMs?: number;
    onPluginPause?: (paused: boolean) => {
        paused: boolean;
        state: string;
        ack_ms: number;
    };
}
export declare function startPluginTransport(opts: PluginTransportOpts): Promise<PluginTransport>;
