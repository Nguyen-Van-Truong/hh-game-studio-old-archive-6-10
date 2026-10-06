import type { ToolResult } from "./executor.js";
export type HostMode = "persistent" | "interactive";
export type HostPhase = "running" | "held_after_decision" | "awaiting_model" | "observing" | "done" | "failed" | "cancelled";
export interface InFlight {
    tool: string;
    action: string;
    params: Record<string, unknown>;
    command_id: string;
    task_id: string;
}
export interface ToolRecord {
    task_id: string;
    command_id: string;
    tool: string;
    action: string;
    result: ToolResult;
    params?: Record<string, unknown>;
}
export interface HostState {
    session_id: string;
    task_id: string;
    command_id: string;
    started_at: number;
    deadline_at: number;
    heartbeat_at: number;
    session_ms: number;
    phase: HostPhase;
    mode: HostMode;
    provider: string;
    model: string;
    budget: {
        max_steps: number;
        used_steps: number;
    };
    cancelled: boolean;
    compacted: boolean;
    plan: {
        summary: string;
    };
    context_summary: string;
    /** Dedicated HOST stamp. Set after waitForPlugin / first MCP ACK, or fake at create. */
    executor?: "mcp-stdio" | "fake";
    tools: ToolRecord[];
    transcript: unknown[];
    writer_pid: number;
    persist_path: string;
    last_observe_ok_at?: number;
    inflight?: InFlight;
    wakeup_at?: number;
    handoff?: {
        from_pid: number;
        to_pid: number;
        at: number;
    };
}
export declare function newHostState(input: {
    session_id: string;
    task_id: string;
    command_id: string;
    mode: HostMode;
    provider: string;
    model: string;
    max_steps: number;
    persist_path: string;
    now?: number;
}): HostState;
export declare function parseHostState(value: unknown): HostState;
export declare function saveHostState(state: HostState): void;
export declare function loadHostState(sessionId: string): HostState;
export declare function compactState(state: HostState): HostState;
export declare function assertRunnable(state: HostState, now?: number): void;
export declare function pidAlive(pid: number): boolean;
