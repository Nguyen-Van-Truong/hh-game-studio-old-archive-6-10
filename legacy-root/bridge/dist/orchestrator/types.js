/** R7-WP2 orchestrator record. Persistable under r7w2/. */
export const ORCH_SCHEMA = "hh-orch/1";
export const ORCH_DIR = "r7w2";
export const ORCH_HEARTBEAT_STALE_MS = 5_000;
export const ORCH_MAX_SAME_REPAIR = 3;
export const DEFAULT_BUDGETS = {
    commands: 64,
    wall_ms: 600_000,
    retries: 8,
    context_tokens: 250_000,
};
export const ORCH_STATES = [
    "inspect",
    "plan",
    "checkpoint",
    "execute",
    "verify",
    "repair",
    "review-ready",
    "done",
    "blocked",
    "cancelled",
];
export const TERMINAL_STATES = new Set(["done", "blocked", "cancelled"]);
export const MUTATING_STATES = new Set(["checkpoint", "execute", "repair"]);
export function isOrchState(value) {
    return ORCH_STATES.includes(value);
}
export function isOrchFixture(value) {
    return value === "ok_slice" || value === "infinite_repair" || value === "dep_fail";
}
export function canTransition(from, to) {
    if (from === to) {
        return true;
    }
    if (TERMINAL_STATES.has(from)) {
        return false;
    }
    if (to === "cancelled" || to === "blocked") {
        return true;
    }
    if (from === "inspect" && to === "plan") {
        return true;
    }
    if (from === "plan" && to === "checkpoint") {
        return true;
    }
    if (from === "checkpoint" && to === "execute") {
        return true;
    }
    if (from === "execute" && to === "verify") {
        return true;
    }
    if (from === "verify" && (to === "repair" || to === "execute" || to === "review-ready" || to === "done")) {
        return true;
    }
    if (from === "repair" && to === "verify") {
        return true;
    }
    if (from === "review-ready" && to === "done") {
        return true;
    }
    return false;
}
