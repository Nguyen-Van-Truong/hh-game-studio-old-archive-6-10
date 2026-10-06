/** Durable command ledger: flush before dispatch, dedup, uncertain recovery. */
import { type PolicyServices } from "../policy/engine.js";
import { DEFAULT_POLICY, normalizePolicy } from "../policy/profiles.js";
import { type PluginCommandResult } from "../transport/plugin_rpc.js";
import { type CommandLedger, type CommandRow } from "./store.js";
export { DEFAULT_POLICY as DEFAULT_LEDGER_POLICY, normalizePolicy };
export interface LedgerBound {
    actorId: string;
    projectId: string;
    policy: string;
}
export interface PluginReadback {
    command_id: string;
    found: boolean;
    ok: boolean;
    postcondition: {
        verified: boolean;
        checks: string[];
    };
}
export interface LedgerRuntime {
    dispatch(envelope: Record<string, unknown>, timeoutMs: number): Promise<PluginCommandResult>;
    readPostcondition(commandId: string): Promise<PluginReadback>;
    pluginConnected(): boolean;
    killPlugin?: () => void;
    policy?: PolicyServices;
    projectRoot?: string;
}
export declare function isNoopVerified(post: {
    verified: boolean;
    checks: string[];
}): boolean;
export declare function errorResult(commandId: string, code: string, message: string, path?: string): PluginCommandResult;
export declare function parseStoredResult(raw: string, commandId: string): PluginCommandResult | undefined;
export declare function isReadVerified(post: {
    verified: boolean;
    checks: string[];
}, actionId: string): boolean;
export declare function executeCommand(ledger: CommandLedger, envelope: Record<string, unknown>, bound: LedgerBound, runtime: LedgerRuntime): Promise<PluginCommandResult>;
export declare function inspectRow(row: CommandRow): Record<string, unknown>;
