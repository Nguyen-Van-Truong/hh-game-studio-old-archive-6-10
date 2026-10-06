/** Typed host errors. E_EXTERNAL lives here so the bridge registry is not churned. */
export declare const E: {
    readonly E_EXTERNAL: "E_EXTERNAL";
    readonly E_POLICY: "E_POLICY";
    readonly E_CANCELLED: "E_CANCELLED";
    readonly E_TIMEOUT: "E_TIMEOUT";
    readonly E_BUSY: "E_BUSY";
    readonly E_PATH: "E_PATH";
    readonly E_INVALID_COMMAND_ID: "E_INVALID_COMMAND_ID";
    readonly E_UNVERIFIED: "E_UNVERIFIED";
};
export type ErrorCode = (typeof E)[keyof typeof E];
export type TypedError = {
    code: string;
    message: string;
    path: string;
};
export declare function typedError(code: string, message: string, path?: string): TypedError;
export declare class HostError extends Error {
    readonly code: string;
    readonly path: string;
    constructor(code: string, message: string, path: string);
    static from(err: TypedError): HostError;
    typed(): TypedError;
}
export declare function isTypedError(value: unknown): value is TypedError;
