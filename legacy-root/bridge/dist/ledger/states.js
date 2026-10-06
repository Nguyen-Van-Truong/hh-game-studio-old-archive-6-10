/** §5.4 command ledger states. Terminal: committed_durable | failed | uncertain. */
export const LEDGER_STATES = [
    "received",
    "validated",
    "applying",
    "applied_volatile",
    "verified",
    "committed_durable",
    "failed",
    "uncertain",
];
export const FAULT_HOOKS = ["received", "validated", "applying", "verified"];
export const TERMINAL_STATES = new Set([
    "committed_durable",
    "failed",
    "uncertain",
]);
export function isLedgerState(value) {
    return LEDGER_STATES.includes(value);
}
export function isFaultHook(value) {
    return FAULT_HOOKS.includes(value);
}
