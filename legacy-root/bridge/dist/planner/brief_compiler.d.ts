/**
 * PROJECT_BRIEF → task DAG. Sidecar source of truth for R7-WP1.
 * Small gaps follow plan §6.2. E1–E4 become blocker nodes, never silent picks.
 */
export declare const PLAN_SCHEMA: "hh-plan/1";
export declare const PINNED_GODOT = "4.7.1-stable";
export type GateCode = "E1" | "E2" | "E3" | "E4";
export type TaskKind = "test" | "verify" | "produce" | "checkpoint" | "blocker";
export interface TaskNode {
    id: string;
    kind: TaskKind;
    acceptance: string[];
    outputs: string[];
    files: string[];
    scene_leases: string[];
    deps: string[];
    verify: string;
    budget: {
        commands: number;
        minutes: number;
    };
    rollback: string;
    commands: string[];
    checkpoint: string;
    criterion?: string;
    blocker?: {
        code: GateCode;
        message: string;
    };
}
export interface AcceptanceItem {
    id: string;
    text: string;
    task_ids: string[];
}
export interface Assumption {
    id: string;
    field: string;
    value: string;
    rule: string;
}
export interface Blocker {
    code: GateCode;
    message: string;
    task_id: string;
}
export interface TraceRow {
    brief: string;
    task: string;
    command: string;
    test: string;
    checkpoint: string;
}
export interface CompiledPlan {
    ok: boolean;
    schema: typeof PLAN_SCHEMA;
    status: "ready" | "blocked" | "invalid";
    run_id: string;
    complete: boolean;
    acyclic: boolean;
    tasks: TaskNode[];
    acceptance: AcceptanceItem[];
    assumptions: Assumption[];
    blockers: Blocker[];
    traces: TraceRow[];
    cards: Array<{
        id: string;
        kind: string;
        summary: string;
    }>;
    error?: {
        code: string;
        message: string;
        path: string;
    };
}
export interface CompileInput {
    brief?: string;
    fields?: Record<string, unknown>;
    run_id?: string;
    inject_cycle?: boolean;
}
export declare const CYCLIC_FIXTURE: Array<{
    id: string;
    deps: string[];
}>;
export declare function detectCycle(tasks: Array<{
    id: string;
    deps?: string[];
}>): string[];
export declare function compileBrief(input: CompileInput): CompiledPlan;
export declare function renderAssumptionsMarkdown(plan: CompiledPlan): string;
export declare function writePlanEvidence(projectRoot: string, plan: CompiledPlan): {
    assumptions: string;
    plan: string;
};
