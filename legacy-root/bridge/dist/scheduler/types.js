/** R7-WP4 multi-agent scheduler record. Persistable under r7w4/. */
export const SCHED_SCHEMA = "hh-sched/1";
export const SCHED_DIR = "r7w4";
export const COORDINATOR_ID = "coordinator";
export const EMPTY_SHA256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
export const DEFAULT_WORK_UNITS = 8_000;
export const THROUGHPUT_SCENES = 8;
export const WORKER_ROLES = [
    "research",
    "code_staging",
    "asset_generation",
    "test_analysis",
];
export const SCHED_OPS = [
    "run",
    "propose",
    "lease",
    "heartbeat",
    "release",
    "merge",
    "status",
    "apply",
    "hold_lane",
    "release_lane",
];
export const SCHED_FIXTURES = ["overlap", "throughput", "crash", "dag"];
export function isWorkerRole(value) {
    return WORKER_ROLES.includes(value);
}
export function isSchedOp(value) {
    return SCHED_OPS.includes(value);
}
export function isSchedFixture(value) {
    return SCHED_FIXTURES.includes(value);
}
export function rolesOverlap(stamps) {
    if (stamps.length < 4) {
        return false;
    }
    const starts = stamps.map((row) => row.started_at_ms);
    const ends = stamps.map((row) => row.ended_at_ms);
    return Math.max(...starts) < Math.min(...ends);
}
