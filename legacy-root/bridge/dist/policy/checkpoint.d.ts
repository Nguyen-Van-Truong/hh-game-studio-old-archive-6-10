/** Recovery checkpoint primitive (A10). Manifest + COW/quarantine; Git ref if the tree is clean. */
export interface CheckpointFile {
    rel: string;
    sha256: string;
    missing: boolean;
}
export interface CheckpointManifest {
    checkpoint_id: string;
    command_id: string;
    created_at: string;
    project_root: string;
    git_ref: string;
    git_head: string;
    files: CheckpointFile[];
    referenced_by: string[];
    hard_delete_blocked: boolean;
}
export interface CheckpointOk {
    ok: true;
    checkpoint_id: string;
    dir: string;
    manifest_path: string;
    manifest: CheckpointManifest;
}
export interface CheckpointErr {
    ok: false;
    error: {
        code: string;
        message: string;
        path: string;
    };
}
export type CheckpointResult = CheckpointOk | CheckpointErr;
export declare function findReferences(projectRoot: string, rel: string): string[];
export declare function createRecoveryCheckpoint(opts: {
    projectRoot: string;
    commandId: string;
    targets: readonly string[];
    fail?: boolean;
}): CheckpointResult;
export declare function resolveCheckpointRef(projectRoot: string, ref: string): string | undefined;
export declare function restoreCheckpoint(manifestPath: string): {
    ok: true;
    restored: string[];
    deleted: string[];
} | CheckpointErr;
