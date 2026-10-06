import { type ChildProcess, type SpawnOptions } from "node:child_process";
/** Argv-array supervisor. Spawn only; shell disabled. */
export declare class ProcessSupervisor {
    private readonly children;
    spawnAgent(file: string, argv: readonly string[], opts?: SpawnOptions): ChildProcess;
    spawn(file: string, argv: readonly string[], opts?: SpawnOptions): ChildProcess;
    runSync(file: string, argv: readonly string[], opts?: SpawnOptions): {
        status: number | null;
        stdout: string;
        stderr: string;
    };
    shutdown(timeoutMs?: number): Promise<void>;
}
export declare function pidAlive(pid: number): boolean;
