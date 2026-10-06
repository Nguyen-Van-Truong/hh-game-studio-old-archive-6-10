/** Merge staged code only when the on-disk base hash still matches. No blind auto-resolve. */
export declare function mergeStaged(opts: {
    projectRoot: string;
    jobId: string;
    writerId: string;
    rel: string;
    baseHash: string;
    contents: string;
}): {
    ok: true;
    rel: string;
    hash: string;
    merged: true;
} | {
    ok: false;
    code: string;
    message: string;
    path: string;
    merged: false;
};
