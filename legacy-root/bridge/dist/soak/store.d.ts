/** Atomic persist for soak state. Jail: r7w5/ only, no .. / addons / .hh-agent. */
import type { PluginCommandResult } from "../transport/plugin_rpc.js";
import { type SoakRecord, type SoakView } from "./types.js";
export declare function jobIdOk(jobId: string): boolean;
export declare function jailSoakRel(projectRoot: string, rel: string): {
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
export declare function newRecord(jobId: string, now: number): SoakRecord;
export declare function loadRecord(projectRoot: string, jobId: string): SoakRecord | undefined;
export declare function saveRecord(projectRoot: string, rec: SoakRecord): {
    ok: true;
    rel: string;
} | {
    ok: false;
    code: string;
    message: string;
    path: string;
};
export declare function currentJobId(projectRoot: string): string;
export declare function listRecords(projectRoot: string): SoakRecord[];
export declare function viewOf(rec: SoakRecord): SoakView;
export declare function publicStateResource(projectRoot: string): Record<string, unknown>;
export declare function appendEvent(projectRoot: string, jobId: string, event: Record<string, unknown>): void;
export declare function rotateEventsIfNeeded(projectRoot: string, jobId: string): {
    rotated: boolean;
    refs: string[];
};
export declare function rememberSoakResult(projectRoot: string, commandId: string, result: PluginCommandResult): void;
export declare function lookupSoakCached(projectRoot: string, commandId: string): PluginCommandResult | undefined;
export declare function capEvidence(projectRoot: string, jobId: string): void;
export declare function writeEvidence(projectRoot: string, jobId: string, name: string, body: unknown): string;
export declare function leakBytes(projectRoot: string, jobId: string): {
    events: number;
    evidence: number;
    cache: number;
};
export declare function typedFail(commandId: string, code: string, message: string, pathName: string): {
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
