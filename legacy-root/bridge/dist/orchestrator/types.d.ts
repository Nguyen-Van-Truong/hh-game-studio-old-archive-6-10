/** R7-WP2 orchestrator record. Persistable under r7w2/. */
export declare const ORCH_SCHEMA: "hh-orch/1";
export declare const ORCH_DIR = "r7w2";
export declare const ORCH_HEARTBEAT_STALE_MS = 5000;
export declare const ORCH_MAX_SAME_REPAIR = 3;
export declare const DEFAULT_BUDGETS: {
    readonly commands: 64;
    readonly wall_ms: 600000;
    readonly retries: 8;
    readonly context_tokens: 250000;
};
export declare const ORCH_STATES: readonly ["inspect", "plan", "checkpoint", "execute", "verify", "repair", "review-ready", "done", "blocked", "cancelled"];
export type OrchState = (typeof ORCH_STATES)[number];
export declare const TERMINAL_STATES: ReadonlySet<OrchState>;
export declare const MUTATING_STATES: ReadonlySet<OrchState>;
export type OrchFixture = "ok_slice" | "infinite_repair" | "dep_fail";
export type TaskRunStatus = "pending" | "running" | "ok" | "failed" | "cancelled" | "skipped";
export interface OrchTask {
    id: string;
    kind: string;
    deps: string[];
    commands: string[];
    verify: string;
}
export interface TaskCommand {
    action: string;
    command_id: string;
    committed: boolean;
}
export interface OrchBudgets {
    commands: number;
    wall_ms: number;
    retries: number;
    context_tokens: number;
}
export interface OrchUsed {
    commands: number;
    wall_ms: number;
    retries: number;
    context_tokens: number;
}
export interface OrchRepair {
    error_key: string;
    same_error_count: number;
    loops: number;
    root_cause: string;
}
export interface OrchRecord {
    schema: typeof ORCH_SCHEMA;
    job_id: string;
    state: OrchState;
    current_task_id: string;
    current_command_id: string;
    committed_command_ids: string[];
    tasks: OrchTask[];
    task_status: Record<string, TaskRunStatus>;
    task_commands: Record<string, TaskCommand[]>;
    started_at_ms: number;
    heartbeat_at_ms: number;
    budgets: OrchBudgets;
    used: OrchUsed;
    repair: OrchRepair;
    checkpoint_ref: string;
    fixture: string;
    hold_after: string;
    blocked_reason: string;
    cancel_requested: boolean;
    cancelled: boolean;
    brief_hash: string;
    applied_state: string;
}
export interface OrchView {
    job_id: string;
    state: OrchState;
    current_task_id: string;
    current_command_id: string;
    committed_command_ids: string[];
    heartbeat_at_ms: number;
    heartbeat_age_ms: number;
    stale: boolean;
    budgets: OrchBudgets;
    used: OrchUsed;
    blocked_reason: string;
    cancelled: boolean;
    fixture: string;
    checkpoint_ref: string;
    repair: OrchRepair;
    task_status: Record<string, TaskRunStatus>;
    tasks_executed: string[];
}
export interface RunInput {
    job_id: string;
    brief?: string;
    path?: string;
    fixture?: OrchFixture;
    hold_after?: OrchState;
    max_steps?: number;
    resume?: boolean;
    fail_task?: string;
    budgets?: Partial<OrchBudgets>;
}
export declare function isOrchState(value: string): value is OrchState;
export declare function isOrchFixture(value: string): value is OrchFixture;
export declare function canTransition(from: OrchState, to: OrchState): boolean;
