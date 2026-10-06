/** Pause mutation gate (A14). ACK is the closed/draining flag, measured with hrtime. */
export declare const PAUSE_ACK_BUDGET_MS = 250;
export interface PauseJob {
    id: string;
    cancellable: boolean;
    atomic: boolean;
    cancelled: boolean;
    finished: boolean;
}
export interface PauseAck {
    paused: boolean;
    state: "open" | "draining";
    ack_ms: number;
    cancelled_jobs: string[];
}
export declare const MUTATE_LANE_JOB = "mutate-lane";
export declare class PauseGate {
    private paused;
    private readonly jobs;
    lastAck: PauseAck;
    constructor();
    isPaused(): boolean;
    registerJob(id: string, opts?: {
        cancellable?: boolean;
        atomic?: boolean;
    }): PauseJob;
    finishJob(id: string): void;
    job(id: string): PauseJob | undefined;
    allowsSideEffect(side: string): boolean;
    pause(): PauseAck;
    resume(): PauseAck;
    measureSamples(count: number): {
        samples: number[];
        p95: number;
    };
}
