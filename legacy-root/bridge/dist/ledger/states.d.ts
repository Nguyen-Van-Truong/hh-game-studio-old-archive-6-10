/** §5.4 command ledger states. Terminal: committed_durable | failed | uncertain. */
export declare const LEDGER_STATES: readonly ["received", "validated", "applying", "applied_volatile", "verified", "committed_durable", "failed", "uncertain"];
export type LedgerState = (typeof LEDGER_STATES)[number];
export declare const FAULT_HOOKS: readonly ["received", "validated", "applying", "verified"];
export type FaultHook = (typeof FAULT_HOOKS)[number];
export declare const TERMINAL_STATES: ReadonlySet<LedgerState>;
export declare function isLedgerState(value: string): value is LedgerState;
export declare function isFaultHook(value: string): value is FaultHook;
