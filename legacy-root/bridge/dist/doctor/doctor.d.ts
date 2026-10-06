import { LOOPBACK_HOST } from "../transport/loopback.js";
import { PROTOCOL, REGISTRY_VERSION } from "../registry/types.js";
import { type SessionDescriptor } from "../session/descriptor.js";
import { PINNED_VERSION_ID } from "./pin.js";
export interface DoctorCheck {
    id: string;
    ok: boolean;
    detail: string;
}
export interface DoctorReport {
    ok: boolean;
    protocol: typeof PROTOCOL;
    registry_version: typeof REGISTRY_VERSION;
    pin_version_id: typeof PINNED_VERSION_ID;
    home: "LOCALAPPDATA/HHGodotAgent";
    loopback: typeof LOOPBACK_HOST;
    session_present: boolean;
    pid_alive: boolean;
    descriptor_under_home: boolean;
    token_in_report: boolean;
    checks: string[];
    check_details: DoctorCheck[];
    error?: {
        code: string;
        message: string;
        path: string;
    };
    session?: Record<string, unknown>;
}
export interface DoctorOptions {
    desc?: SessionDescriptor;
    home?: string;
    projectRoot?: string;
    godotExe?: string;
    forceGodotVersion?: string;
    forceProtocol?: string;
    forceSchema?: string;
}
export declare function tokenAbsentFromBlob(blob: string, token: string): boolean;
export declare function runDoctor(opts?: DoctorOptions): DoctorReport;
/** Session-only subset kept for callers that still import the R2-WP2 name. */
export declare function runSessionDoctor(desc?: SessionDescriptor, home?: string): DoctorReport;
export declare function doctorFromProjectId(projectId: string, home?: string): DoctorReport;
