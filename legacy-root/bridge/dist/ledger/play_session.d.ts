/** Last Play run seen after a proven EXTERNAL apply. job.list/status may show it. */
export type PlayJob = {
    id: string;
    kind: "play";
    playing: boolean;
    scene: string;
    previous_run_id: string;
};
export declare function notePlayAfter(actionId: string, after: Record<string, unknown>): void;
export declare function playJobs(): PlayJob[];
export declare function playJob(jobId: string): PlayJob | undefined;
