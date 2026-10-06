/** Jailed soak state resource under r7w5/. Host --compact writes this; sidecar/MCP reads it. */
import type { HostState } from "./session.js";
export declare const SOAK_DIR = "r7w5";
export declare const SOAK_SCHEMA = "hh-soak/1";
export declare const SOAK_RESOURCE_URI = "session://state";
export declare function writeHostSoakResource(input: {
    projectRoot: string;
    jobId: string;
    state: HostState;
}): {
    ok: true;
    resource_path: string;
    resource_uri: string;
} | {
    ok: false;
    message: string;
};
export declare function projectLooksLikeGodot(projectRoot: string): boolean;
