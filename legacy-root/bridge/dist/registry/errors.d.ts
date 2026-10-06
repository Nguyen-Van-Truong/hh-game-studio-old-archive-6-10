/** Typed error codes for envelope/params/variant validation. */
export declare const E: {
    readonly E_UNKNOWN_ACTION: "E_UNKNOWN_ACTION";
    readonly E_PROTOCOL_VERSION: "E_PROTOCOL_VERSION";
    readonly E_ACTION_VERSION: "E_ACTION_VERSION";
    readonly E_UNKNOWN_PARAM: "E_UNKNOWN_PARAM";
    readonly E_MISSING_REQUIRED: "E_MISSING_REQUIRED";
    readonly E_INVALID_TYPE: "E_INVALID_TYPE";
    readonly E_OUT_OF_BOUNDS: "E_OUT_OF_BOUNDS";
    readonly E_INVALID_COMMAND_ID: "E_INVALID_COMMAND_ID";
    readonly E_CLIENT_ESCALATION: "E_CLIENT_ESCALATION";
    readonly E_UNKNOWN_VARIANT_TYPE: "E_UNKNOWN_VARIANT_TYPE";
    readonly E_INVALID_VARIANT: "E_INVALID_VARIANT";
    readonly E_INVALID_ENVELOPE: "E_INVALID_ENVELOPE";
    readonly E_UNVERIFIED: "E_UNVERIFIED";
    readonly E_AUTH: "E_AUTH";
    readonly E_BIND: "E_BIND";
    readonly E_PROJECT_MISMATCH: "E_PROJECT_MISMATCH";
    readonly E_PATH: "E_PATH";
    readonly E_BUSY: "E_BUSY";
    readonly E_IDEMPOTENCY_CONFLICT: "E_IDEMPOTENCY_CONFLICT";
    readonly E_UNCERTAIN: "E_UNCERTAIN";
    readonly E_POLICY: "E_POLICY";
    readonly E_CHECKPOINT: "E_CHECKPOINT";
    readonly E_CONFLICT: "E_CONFLICT";
    readonly E_PAUSED: "E_PAUSED";
    readonly E_LEASE: "E_LEASE";
    readonly E_VERSION_SKEW: "E_VERSION_SKEW";
    readonly E_TIMEOUT: "E_TIMEOUT";
};
export type ErrorCode = (typeof E)[keyof typeof E];
export declare const COMMON_PARAM_ERRORS: readonly ErrorCode[];
export declare function typedError(code: string, message: string, path?: string): {
    code: string;
    message: string;
    path: string;
};
