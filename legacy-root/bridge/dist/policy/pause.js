/** Pause mutation gate (A14). ACK is the closed/draining flag, measured with hrtime. */
import { performance } from "node:perf_hooks";
export const PAUSE_ACK_BUDGET_MS = 250;
export const MUTATE_LANE_JOB = "mutate-lane";
export class PauseGate {
    paused = false;
    jobs = new Map();
    lastAck = { paused: false, state: "open", ack_ms: 0, cancelled_jobs: [] };
    constructor() {
        this.registerJob(MUTATE_LANE_JOB, { cancellable: true });
    }
    isPaused() {
        return this.paused;
    }
    registerJob(id, opts = {}) {
        const job = {
            id,
            cancellable: opts.cancellable === true,
            atomic: opts.atomic === true,
            cancelled: false,
            finished: false,
        };
        this.jobs.set(id, job);
        return job;
    }
    finishJob(id) {
        const job = this.jobs.get(id);
        if (job) {
            job.finished = true;
        }
    }
    job(id) {
        return this.jobs.get(id);
    }
    allowsSideEffect(side) {
        if (!this.paused) {
            return true;
        }
        return side === "read" || side === "view" || side === "";
    }
    pause() {
        const t0 = performance.now();
        this.paused = true;
        const cancelled = [];
        for (const job of this.jobs.values()) {
            if (job.cancellable && !job.finished) {
                job.cancelled = true;
                cancelled.push(job.id);
            }
        }
        const ackMs = performance.now() - t0;
        this.lastAck = { paused: true, state: "draining", ack_ms: ackMs, cancelled_jobs: cancelled };
        return this.lastAck;
    }
    resume() {
        const t0 = performance.now();
        this.paused = false;
        const lane = this.jobs.get(MUTATE_LANE_JOB);
        if (lane) {
            lane.cancelled = false;
            lane.finished = false;
        }
        else {
            this.registerJob(MUTATE_LANE_JOB, { cancellable: true });
        }
        const ackMs = performance.now() - t0;
        this.lastAck = { paused: false, state: "open", ack_ms: ackMs, cancelled_jobs: [] };
        return this.lastAck;
    }
    measureSamples(count) {
        const samples = [];
        for (let i = 0; i < count; i++) {
            this.resume();
            const ack = this.pause();
            samples.push(ack.ack_ms);
        }
        this.resume();
        const sorted = [...samples].sort((a, b) => a - b);
        const idx = Math.max(0, Math.ceil(0.95 * sorted.length) - 1);
        return { samples, p95: sorted[idx] ?? 0 };
    }
}
