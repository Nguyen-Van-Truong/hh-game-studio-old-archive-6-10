/** R9-WP1 sidecar export job supervisor. Godot CLI is spawned by tools/godot/export_job.py. */
import type { PluginCommandResult } from "../transport/plugin_rpc.js";
export interface ExportCtx {
    projectRoot: string;
    commandId: string;
    now: number;
    paused?: boolean;
}
export declare function handleExportAction(actionId: string, ctx: ExportCtx, params: Record<string, unknown>): PluginCommandResult;
