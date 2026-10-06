/** Profile / side-effect gates. OWNER_AUTOPILOT is project-scoped, not unrestricted OS. */
import { type Policy, type SideEffect } from "../registry/types.js";
export declare const DEFAULT_POLICY: Policy;
export declare function normalizePolicy(raw: string | undefined): Policy;
export declare function isPolicy(value: string): value is Policy;
export declare function isMutatingSideEffect(side: string): boolean;
export declare function profileAllows(policy: Policy, side: SideEffect | string, approvedDestructive: boolean): boolean;
export declare function denyProfile(policy: Policy, side: string, approvedDestructive: boolean): {
    code: string;
    message: string;
    path: string;
} | undefined;
