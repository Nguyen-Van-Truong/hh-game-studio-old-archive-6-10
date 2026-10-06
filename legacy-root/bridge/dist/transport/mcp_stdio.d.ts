import { type LedgerBound } from "../ledger/execute.js";
import type { CommandLedger } from "../ledger/store.js";
import type { PauseGate } from "../policy/pause.js";
import type { PolicyServices } from "../policy/engine.js";
import type { SessionLog } from "../session/log.js";
import { type SessionDescriptor } from "../session/descriptor.js";
import type { DoctorReport } from "../doctor/doctor.js";
import { type PluginCommandResult, type PluginReadbackResult } from "./plugin_rpc.js";
export interface McpStdioContext {
    descriptor: () => SessionDescriptor;
    doctor: () => DoctorReport;
    log: SessionLog;
    plugin?: {
        connected: () => boolean;
        dispatch: (envelope: Record<string, unknown>, timeoutMs: number) => Promise<PluginCommandResult>;
        readPostcondition: (commandId: string, timeoutMs: number) => Promise<PluginReadbackResult>;
        dropPlugin: () => void;
        sendControl?: (msg: Record<string, unknown>) => boolean;
    };
    ledger?: CommandLedger;
    bound?: LedgerBound;
    pause?: PauseGate;
    policy?: PolicyServices;
}
export declare function startMcpStdio(ctx: McpStdioContext): void;
