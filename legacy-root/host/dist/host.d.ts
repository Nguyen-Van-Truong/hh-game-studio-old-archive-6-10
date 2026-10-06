import { type ToolExecutor, type ToolResult } from "./executor.js";
import type { Provider } from "./providers/types.js";
import { type HostMode, type HostState } from "./session.js";
export interface HostOptions {
    mode: HostMode;
    providerName: "fake" | "configured" | "plan";
    sessionId?: string;
    taskId?: string;
    commandId?: string;
    scriptPath?: string;
    briefPath?: string;
    mcpProject?: string;
    maxSteps?: number;
    holdAfterDecision?: boolean;
    holdUntilDeadline?: boolean;
    fast?: boolean;
    secrets?: string[];
}
export interface HostReport {
    ok: boolean;
    mode: HostMode;
    provider: string;
    model: string;
    session_id: string;
    task_id: string;
    command_id: string;
    started_at: number;
    deadline_at: number;
    session_ms: number;
    phase: string;
    compacted: boolean;
    persist_path: string;
    tools: Array<{
        task_id: string;
        command_id: string;
        tool: string;
        action: string;
        result: ToolResult;
        params?: Record<string, unknown>;
    }>;
    plan: {
        summary: string;
    };
    context_summary: string;
    executor: "mcp-stdio" | "fake";
    error?: {
        code: string;
        message: string;
        path: string;
    };
}
/**
 * Host is the ONLY class that calls the model and decides the tool loop.
 * Sidecar/plugin stay deterministic execution. Interactive IDE clients are
 * this same class; unattended uses a persistent process of this class.
 */
export declare class Host {
    readonly provider: Provider;
    readonly executor: ToolExecutor;
    readonly secrets: string[];
    private state;
    private readonly holdAfterDecision;
    private readonly holdUntilDeadline;
    private readonly fast;
    private readonly briefText;
    private readonly mcp?;
    private readonly usesMcp;
    private held;
    private constructor();
    static create(opts: HostOptions): Host;
    static resume(opts: HostOptions & {
        sessionId: string;
    }): Host;
    static load(sessionId: string): HostState;
    static compact(sessionId: string, opts?: {
        projectRoot?: string;
        jobId?: string;
    }): HostState;
    static cancel(sessionId: string): HostState;
    private modelContext;
    private log;
    private persist;
    /** Persist HOST only after plugin connect or a live FakeExecutor create. */
    private stampHostExecutor;
    private stampContext;
    private treeHasNodeList;
    /** scene.read success needs a tree with items or a node list, not path + empty dict. */
    private observeHasPayload;
    private noteSuccessfulObserve;
    private finishInflight;
    private hangForKill;
    /**
     * Decide the next tool via the provider, persist in-flight command_id,
     * optionally hold so a test can kill this process, then execute.
     */
    run(): Promise<HostReport>;
    private waitForPlugin;
    private observeUntilDeadline;
    close(): void;
    private writeReportFile;
    report(ok?: boolean): HostReport;
}
export declare function showSession(sessionId: string): Record<string, unknown>;
