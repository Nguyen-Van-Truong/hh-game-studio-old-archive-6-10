import { type TypedError } from "./errors.js";
export interface ToolRequest {
    tool: string;
    action: string;
    params: Record<string, unknown>;
}
export interface ToolSuccess {
    ok: true;
    after: Record<string, unknown>;
    postcondition: {
        verified: boolean;
        checks: string[];
    };
}
export interface ToolFailure {
    ok: false;
    error: TypedError;
    after?: Record<string, unknown>;
}
export type ToolResult = ToolSuccess | ToolFailure;
export interface ToolExecutor {
    execute(req: ToolRequest): ToolResult | Promise<ToolResult>;
}
/** Same stdio MCP tools/call shape as tests/bootstrap/test_session.py. */
export declare function mcpToolsCall(name: string, action: string, params: Record<string, unknown>, id: number, commandId?: string): Record<string, unknown>;
export declare function parseMcpToolResult(msg: unknown): ToolResult;
/**
 * In-process deterministic executor. Does not talk to Godot.
 * Mutate verbs stay E_UNVERIFIED — the host does not apply scene writes.
 */
export declare class FakeExecutor implements ToolExecutor {
    execute(req: ToolRequest): ToolResult;
}
export interface LineStdio {
    writeLine(line: string): void;
    readLine(timeoutMs?: number): string | Promise<string>;
}
/** Sidecar MCP over newline JSON-RPC. Sidecar stays deterministic execution. */
export declare class McpStdioExecutor implements ToolExecutor {
    private readonly io;
    private nextId;
    private initialized;
    constructor(io: LineStdio);
    execute(req: ToolRequest): Promise<ToolResult>;
}
