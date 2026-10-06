/** Soak compact / wake / rotate. Idle must not auto-flip blocked when state is unchanged. */
import type { PluginCommandResult } from "../transport/plugin_rpc.js";
export interface SoakCtx {
    projectRoot: string;
    commandId: string;
    now: number;
}
export declare function handleSoakAction(ctx: SoakCtx, params: Record<string, unknown>): PluginCommandResult;
export declare function statusSoakJob(ctx: SoakCtx, params: Record<string, unknown>): PluginCommandResult;
export declare function listSoakJobs(projectRoot: string): Array<Record<string, unknown>>;
