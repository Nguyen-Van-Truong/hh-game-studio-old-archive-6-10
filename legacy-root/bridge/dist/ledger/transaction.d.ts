/** Transaction coordinator helpers. Checkpoint + compensate; not OS-global atomic. */
import { type CheckpointOk } from "../policy/checkpoint.js";
import type { PluginCommandResult } from "../transport/plugin_rpc.js";
export interface RecoveryReport {
    restored: boolean;
    files: string[];
    deleted: string[];
    error?: string;
}
export declare function isRecord(value: unknown): value is Record<string, unknown>;
export declare function checkpointEvidence(checkpoint: CheckpointOk): Record<string, unknown>;
export declare function mergeAfter(result: PluginCommandResult, extra: Record<string, unknown>): PluginCommandResult;
export declare function compensateFromManifest(manifestPath: string): RecoveryReport;
export declare function applyGitCheckpoint(opts: {
    commandId: string;
    projectRoot: string;
    message: string;
    paths: readonly string[];
    allowlist?: readonly string[];
    repo?: string;
    runId?: string;
    project?: string;
    resume?: boolean;
    pause?: {
        pause: () => {
            paused: boolean;
            state?: string;
            ack_ms?: number;
        };
    };
}): PluginCommandResult;
export declare function applyGitRevert(opts: {
    commandId: string;
    projectRoot: string;
    ref: string;
    pause?: {
        pause: () => {
            paused: boolean;
            state?: string;
            ack_ms?: number;
        };
    };
}): PluginCommandResult;
export declare function transactionApplyOk(result: PluginCommandResult): PluginCommandResult | undefined;
