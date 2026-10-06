/** R7-WP5 soak record. Persistable under r7w5/. */
export const SOAK_DIR = "r7w5";
export const SOAK_SCHEMA = "hh-soak/1";
export const SOAK_CURRENT = "r7w5/current.json";
export const SOAK_EVENT_MAX_LINES = 256;
export const SOAK_EVENT_ROTATE_KEEP = 4;
export const SOAK_CACHE_MAX = 512;
export const SOAK_EVIDENCE_MAX_FILES = 32;
/** Stated LEAK budgets — official test enforces the same numbers. */
export const SOAK_EVENT_BUDGET_BYTES = 2 * 1024 * 1024;
export const SOAK_EVIDENCE_BUDGET_BYTES = 4 * 1024 * 1024;
export const SOAK_CACHE_BUDGET_BYTES = 2 * 1024 * 1024;
