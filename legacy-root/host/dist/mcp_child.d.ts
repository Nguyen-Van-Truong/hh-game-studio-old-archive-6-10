/** Spawn the sidecar and speak newline JSON-RPC MCP. Not a fake executor. */
import type { LineStdio } from "./executor.js";
export interface McpChild extends LineStdio {
    readonly pid: number;
    initialize(): Promise<void>;
    dispose(): void;
}
export declare function spawnMcpChild(opts: {
    projectRoot: string;
    logDir?: string;
}): McpChild;
