/** Atomic persist for orchestrator records. Jail: r7w2/ only, no .. / addons / .hh-agent. */
import { type OrchRecord, type OrchView, type TaskCommand, type TaskRunStatus } from "./types.js";
export declare function jobIdOk(jobId: string): boolean;
export declare function jailOrchRel(projectRoot: string, rel: string): {
    ok: true;
    abs: string;
    rel: string;
} | {
    ok: false;
    code: string;
    message: string;
    path: string;
};
export declare function stateRel(jobId: string): string;
export declare function loadRecord(projectRoot: string, jobId: string): OrchRecord | undefined;
export declare function saveRecord(projectRoot: string, rec: OrchRecord): {
    ok: true;
} | {
    ok: false;
    code: string;
    message: string;
    path: string;
};
export declare function writeEvidence(projectRoot: string, jobId: string, relName: string, body: unknown): string;
export declare function readEvidence(projectRoot: string, jobId: string, relName: string): Record<string, unknown> | undefined;
export declare function listRecords(projectRoot: string): OrchRecord[];
export declare function emptyRepair(): OrchRecord["repair"];
export declare function newRecord(jobId: string, now: number, budgets?: Partial<OrchRecord["budgets"]>): OrchRecord;
export declare function viewOf(rec: OrchRecord, now: number): OrchView;
export declare function typedFail(commandId: string, code: string, message: string, pathName: string, after?: Record<string, unknown>): {
    after?: Record<string, unknown>;
    type: "result";
    ok: false;
    command_id: string;
    changed: boolean;
    postcondition: {
        verified: boolean;
        checks: string[];
    };
    error: {
        code: string;
        message: string;
        path: string;
    };
};
export declare function cloneCommands(rows: TaskCommand[]): TaskCommand[];
export declare function statusName(value: unknown): TaskRunStatus;
