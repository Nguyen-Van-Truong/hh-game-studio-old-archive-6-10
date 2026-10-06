/** Orchestrator state machine. Sidecar driver when the plugin is down. */
import type { PluginCommandResult } from "../transport/plugin_rpc.js";
export interface MachineCtx {
    projectRoot: string;
    commandId: string;
    now: number;
    paused: boolean;
}
export declare function runJob(ctx: MachineCtx, params: Record<string, unknown>): PluginCommandResult;
export declare function statusJob(ctx: MachineCtx, params: Record<string, unknown>): PluginCommandResult;
export declare function listJobs(ctx: MachineCtx, params: Record<string, unknown>): PluginCommandResult;
export declare function cancelJob(ctx: MachineCtx, params: Record<string, unknown>): PluginCommandResult;
export declare function waitJob(ctx: MachineCtx, params: Record<string, unknown>): PluginCommandResult;
export declare function illegalTransition(from: string, to: string): {
    ok: false;
    error: {
        code: string;
        message: string;
        path: string;
    };
} | {
    ok: true;
};
export declare function handleOrchAction(actionId: string, ctx: MachineCtx, params: Record<string, unknown>): PluginCommandResult;
