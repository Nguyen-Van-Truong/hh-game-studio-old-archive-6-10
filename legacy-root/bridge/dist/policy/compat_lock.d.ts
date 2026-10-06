/** Capability-lock / protocol / schema mismatch → Observe/Doctor only (S7). */
export interface CompatLockAssessment {
    mismatch: boolean;
    reason: string;
    protocol: string;
    schema: string;
    lockVersionId: string;
}
export declare function assessCompatLock(projectRoot: string): CompatLockAssessment;
export declare function observeOnlyReason(projectRoot: string | undefined): string;
