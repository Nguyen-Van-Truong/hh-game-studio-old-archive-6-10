/** Four worker roles via worker_threads. Serial path calls the same cpuWork — no extra sleep. */
import { type WorkerStamp } from "./types.js";
export declare function runOverlapWorkers(units?: number): Promise<WorkerStamp[]>;
export declare function runDagWorkers(units?: number): Promise<WorkerStamp[]>;
export declare function sceneSeeds(count: number): string[];
export declare function runThroughputParallel(scenes?: number, units?: number): Promise<{
    ms: number;
    digests: string[];
}>;
export declare function runThroughputSerial(scenes?: number, units?: number): {
    ms: number;
    digests: string[];
};
