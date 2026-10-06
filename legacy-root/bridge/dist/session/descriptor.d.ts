import { PROTOCOL } from "../registry/types.js";
import { type ProcessSupervisor } from "./supervisor.js";
export interface SessionDescriptor {
    protocol: typeof PROTOCOL;
    project_id: string;
    project_root: string;
    host: "127.0.0.1";
    port: number;
    pid: number;
    started_at: string;
    token: string;
}
export declare function publicDescriptorView(desc: SessionDescriptor): Record<string, unknown>;
export declare function cleanupStaleSessions(home: string): void;
export declare function acquireProjectLock(projectId: string, supervisor: ProcessSupervisor, home: string): void;
export declare function writeDescriptor(desc: SessionDescriptor, supervisor: ProcessSupervisor, home: string): string;
export declare function readDescriptor(projectId: string, home: string): SessionDescriptor;
export declare function removeSessionFiles(projectId: string, home: string): void;
