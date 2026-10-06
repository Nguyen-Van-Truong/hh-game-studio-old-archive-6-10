/** Atomic persist for scheduler records. Jail: r7w4/ only, no .. / addons / .hh-agent. */
import { type SchedRecord } from "./types.js";
export declare function jobIdOk(jobId: string): boolean;
export declare function jailSchedRel(projectRoot: string, rel: string): {
    ok: true;
    abs: string;
    rel: string;
} | {
    ok: false;
    code: string;
    message: string;
    path: string;
};
export declare function atomicWriteUtf8(absPath: string, text: string): boolean;
export declare function stateRel(jobId: string): string;
export declare function progressRel(jobId: string): string;
export declare function generatedRel(jobId: string, name: string): string;
export declare function registryRel(jobId: string, name: string): string;
export declare function coordinatorOwnedRel(rel: string): boolean;
export declare function fileDigest(absPath: string): string;
export declare function textDigest(text: string): string;
export declare function loadRecord(projectRoot: string, jobId: string): SchedRecord | undefined;
export declare function saveRecord(projectRoot: string, rec: SchedRecord): {
    ok: true;
} | {
    ok: false;
    code: string;
    message: string;
    path: string;
};
export declare function writeOwned(projectRoot: string, rel: string, body: unknown): {
    ok: true;
    rel: string;
} | {
    ok: false;
    code: string;
    message: string;
    path: string;
};
export declare function listRecords(projectRoot: string): SchedRecord[];
export declare function newRecord(jobId: string, now: number, fixture?: string): SchedRecord;
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
