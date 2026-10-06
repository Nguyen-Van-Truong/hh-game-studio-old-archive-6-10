/** Compose profile, pause, jail, leases, and recovery checkpoint before applying. */
import type { Policy, SideEffect } from "../registry/types.js";
import { ApprovalBinder } from "./approve.js";
import { type CheckpointOk } from "./checkpoint.js";
import { type JailOk } from "./jail.js";
import { LeaseTable } from "./leases.js";
import { PauseGate } from "./pause.js";
export interface PolicyServices {
    projectRoot: string;
    writerId: string;
    pause: PauseGate;
    leases: LeaseTable;
    approvals?: ApprovalBinder;
    approvalToken?: string;
    revision?: string;
    checkpointFail?: boolean;
}
export interface GateInput {
    commandId: string;
    sideEffect: SideEffect | string;
    actionId: string;
    checkpointRequired: boolean;
    policy: Policy;
    params: Record<string, unknown>;
    requestHash?: string;
    services?: PolicyServices;
}
export interface GateDenied {
    ok: false;
    error: {
        code: string;
        message: string;
        path: string;
    };
}
export interface GateAllowed {
    ok: true;
    jailed: JailOk[];
    checkpoint?: CheckpointOk;
}
export type GateResult = GateDenied | GateAllowed;
export declare function runMutationGate(input: GateInput): GateResult;
