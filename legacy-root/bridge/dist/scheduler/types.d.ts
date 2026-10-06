/** R7-WP4 multi-agent scheduler record. Persistable under r7w4/. */
export declare const SCHED_SCHEMA: "hh-sched/1";
export declare const SCHED_DIR = "r7w4";
export declare const COORDINATOR_ID = "coordinator";
export declare const EMPTY_SHA256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
export declare const DEFAULT_WORK_UNITS = 8000;
export declare const THROUGHPUT_SCENES = 8;
export declare const WORKER_ROLES: readonly ["research", "code_staging", "asset_generation", "test_analysis"];
export type WorkerRole = (typeof WORKER_ROLES)[number];
export declare const SCHED_OPS: readonly ["run", "propose", "lease", "heartbeat", "release", "merge", "status", "apply", "hold_lane", "release_lane"];
export type SchedOp = (typeof SCHED_OPS)[number];
export declare const SCHED_FIXTURES: readonly ["overlap", "throughput", "crash", "dag"];
export type SchedFixture = (typeof SCHED_FIXTURES)[number];
export type ProposalStatus = "proposed" | "merged" | "conflict";
export interface WorkerStamp {
    role: WorkerRole;
    started_at_ms: number;
    ended_at_ms: number;
    digest: string;
    thread_id: number;
}
export interface ChangeProposal {
    proposal_id: string;
    writer_id: string;
    role: string;
    path: string;
    base_hash: string;
    contents: string;
    created_at_ms: number;
    status: ProposalStatus;
}
export interface LaneEvent {
    at_ms: number;
    writer_id: string;
    path: string;
    op: string;
}
export interface SchedRecord {
    schema: typeof SCHED_SCHEMA;
    job_id: string;
    state: "idle" | "running" | "done" | "conflict" | "blocked";
    started_at_ms: number;
    heartbeat_at_ms: number;
    fixture: string;
    workers: WorkerStamp[];
    proposals: ChangeProposal[];
    progress: Record<string, unknown>;
    generated: Record<string, unknown>;
    registry: Record<string, unknown>;
    lane: LaneEvent[];
    overlap: boolean;
    serial_ms: number;
    parallel_ms: number;
    blocked_reason: string;
}
export declare function isWorkerRole(value: string): value is WorkerRole;
export declare function isSchedOp(value: string): value is SchedOp;
export declare function isSchedFixture(value: string): value is SchedFixture;
export declare function rolesOverlap(stamps: WorkerStamp[]): boolean;
