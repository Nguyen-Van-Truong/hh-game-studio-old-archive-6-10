export declare const PLUGIN_NOOP_METHOD: "hh.plugin";
export declare const PLUGIN_NOOP_ACTION: "noop";
export interface PluginCommandResult {
    type: "result";
    ok: boolean;
    command_id: string;
    changed: boolean;
    postcondition: {
        verified: boolean;
        checks: string[];
    };
    error?: {
        code: string;
        message: string;
        path: string;
    };
    after?: Record<string, unknown>;
    before?: Record<string, unknown>;
    undo_action?: string;
    warnings?: string[];
    evidence?: string[];
}
export declare function isNoopEnvelope(env: {
    method?: unknown;
    action?: unknown;
}): boolean;
export declare const PLUGIN_READBACK_TYPE: "readback";
export declare const PLUGIN_READBACK_RESULT_TYPE: "readback_result";
export interface PluginReadbackResult {
    type: typeof PLUGIN_READBACK_RESULT_TYPE;
    command_id: string;
    found: boolean;
    ok: boolean;
    postcondition: {
        verified: boolean;
        checks: string[];
    };
}
export declare function emptyReadback(commandId: string): PluginReadbackResult;
export declare function parsePluginReadback(raw: unknown): PluginReadbackResult | null;
export declare function unverifiedResult(commandId: string, message: string): PluginCommandResult;
export declare function busyResult(commandId: string, message: string): PluginCommandResult;
export declare function parsePluginResult(raw: unknown): PluginCommandResult | null;
export declare function guardPaperSuccess(result: PluginCommandResult, envelope: {
    method?: unknown;
    action?: unknown;
}): PluginCommandResult;
