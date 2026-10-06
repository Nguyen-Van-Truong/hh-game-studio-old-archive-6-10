import type { ProcessSupervisor } from "../session/supervisor.js";
import { type SqliteDatabase } from "./node_sqlite.js";
import { type LedgerState } from "./states.js";
export interface CommandRow {
    command_id: string;
    request_hash: string;
    actor_id: string;
    project_id: string;
    policy: string;
    method: string;
    action: string;
    action_id: string;
    side_effect: string;
    state: LedgerState;
    envelope_json: string;
    result_json: string;
    error_code: string;
    error_message: string;
    postcondition_json: string;
    precondition_json: string;
    before_summary: string;
    after_summary: string;
    apply_count: number;
    dispatch_attempted: number;
    evidence_json: string;
    created_at: string;
    updated_at: string;
}
export interface CheckpointRow {
    checkpoint_id: string;
    command_id: string;
    evidence_json: string;
    created_at: string;
}
export interface OpenLedgerOpts {
    projectId: string;
    supervisor: ProcessSupervisor;
    home?: string;
}
export declare class CommandLedger {
    readonly filePath: string;
    readonly projectId: string;
    readonly home: string;
    private readonly db;
    constructor(filePath: string, projectId: string, home: string, db: SqliteDatabase);
    pragmaInfo(): {
        journal_mode: string;
        synchronous: number;
    };
    get(commandId: string): CommandRow | undefined;
    listInFlight(): CommandRow[];
    insertReceived(row: CommandRow): void;
    save(row: CommandRow): void;
    flush(): void;
    attachEvidence(commandId: string, refs: readonly string[]): CommandRow;
    addCheckpoint(checkpointId: string, evidenceRefs: readonly string[], commandId?: string): void;
    listCheckpoints(): CheckpointRow[];
    /** Drop old committed/failed rows that a live checkpoint does not still name. */
    compact(nowMs: number, maxAgeMs: number): {
        deleted: number;
        kept: number;
    };
    close(): void;
}
export declare function emptyRow(partial: Omit<CommandRow, "created_at" | "updated_at"> & {
    created_at?: string;
    updated_at?: string;
}): CommandRow;
export declare function openLedger(opts: OpenLedgerOpts): CommandLedger;
