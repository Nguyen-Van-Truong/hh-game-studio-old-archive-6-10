import { type FaultHook } from "./states.js";
export declare const LEDGER_FAULT_EXIT: 99;
export declare const LEDGER_ATTEMPT_CRASH_EXIT: 98;
export declare class LedgerPluginDeath extends Error {
    readonly hook: FaultHook;
    constructor(hook: FaultHook);
}
/** Kill sidecar, or throw so the caller can drop the plugin, after a flushed state. */
export declare function maybeFault(hook: FaultHook, commandId: string): void;
export declare function maybeCrashAfterDispatchAttempt(commandId: string): void;
export declare function faultEnvError(hook: string): {
    code: string;
    message: string;
    path: string;
};
