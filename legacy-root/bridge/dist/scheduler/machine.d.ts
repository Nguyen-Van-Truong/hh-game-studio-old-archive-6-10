/** Multi-agent scheduler. Coordinator owns registry/generated/progress; workers propose. */
import type { PluginCommandResult } from "../transport/plugin_rpc.js";
import { type WorkerRole } from "./types.js";
export interface SchedCtx {
    projectRoot: string;
    commandId: string;
    now: number;
    paused: boolean;
}
export declare function statusSchedJob(ctx: SchedCtx, params: Record<string, unknown>): PluginCommandResult;
export declare function listSchedJobs(ctx: SchedCtx, limit: number): Record<string, unknown>[];
export declare function handleScheduleAction(ctx: SchedCtx, params: Record<string, unknown>): Promise<PluginCommandResult>;
export declare function peekFileHash(projectRoot: string, rawPath: string): string;
export declare function isSchedRole(value: string): value is WorkerRole;
