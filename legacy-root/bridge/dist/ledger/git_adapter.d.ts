/** Real Git slice checkpoint / LFS / revert. Jailed worktree only. No history rewrite. */
import type { PluginCommandResult } from "../transport/plugin_rpc.js";
import { type JailedGit } from "./git_jail.js";
export declare const GIT_CKPT_SCHEMA = "hh-git-ckpt/1";
export interface GitStatusFile {
    path: string;
    xy: string;
    kind: "allowlisted" | "dirty_user" | "untracked_asset" | "conflicted" | "secret" | "other";
}
export interface GitStatusReport {
    repo: string;
    jailed: boolean;
    parent_walk_refused: boolean;
    branch: string;
    detached: boolean;
    head: string;
    dirty_user: string[];
    allowlisted: string[];
    untracked_assets: string[];
    conflicted: string[];
    secrets_redacted: boolean;
    files: GitStatusFile[];
    checkpoint_id: string;
    checkpoint_commit: string;
    checkpoint_branch: string;
    checkpoint_ref: string;
    resume_ok: boolean;
    source: string;
}
export interface GitAssetRow {
    path: string;
    size: number;
    sha256: string;
    lfs: boolean;
}
export interface GitCheckpointManifest {
    schema: typeof GIT_CKPT_SCHEMA;
    checkpoint_id: string;
    command_id: string;
    created_at: string;
    project: string;
    run_id: string;
    branch: string;
    git_commit: string;
    git_ref: string;
    git_real: true;
    repo_rel: string;
    files: {
        rel: string;
        git_path: string;
        sha256: string;
    }[];
    assets: GitAssetRow[];
    dirty_user: string[];
    untracked_assets: string[];
    lfs_threshold: number;
    lfs_available: boolean;
}
export declare function lfsAvailable(git: JailedGit): boolean;
export declare function parseStatusPorcelain(text: string, git: JailedGit, projectRoot: string, allowlist: readonly string[]): Omit<GitStatusReport, "checkpoint_id" | "checkpoint_commit" | "checkpoint_branch" | "checkpoint_ref" | "resume_ok">;
export declare function listGitManifests(projectRoot: string): {
    abs: string;
    rel: string;
    manifest: GitCheckpointManifest;
}[];
export declare function resolveGitManifest(projectRoot: string, ref: string): {
    abs: string;
    rel: string;
    manifest: GitCheckpointManifest;
} | undefined;
export declare function readGitStatus(opts: {
    projectRoot: string;
    repo?: string;
    runId?: string;
    allowlist?: readonly string[];
}): GitStatusReport;
export declare function readGitDiff(opts: {
    projectRoot: string;
    path: string;
    repo?: string;
}): {
    ok: true;
    path: string;
    text: string;
    source: string;
} | {
    ok: false;
    error: {
        code: string;
        message: string;
        path: string;
    };
};
export declare function applyGitSliceCheckpoint(opts: {
    commandId: string;
    projectRoot: string;
    message: string;
    paths: readonly string[];
    allowlist?: readonly string[];
    repo?: string;
    runId?: string;
    project?: string;
    resume?: boolean;
    pause?: {
        pause: () => {
            paused: boolean;
            state?: string;
            ack_ms?: number;
        };
    };
}): PluginCommandResult;
export declare function applyGitResume(opts: {
    commandId: string;
    projectRoot: string;
    runId: string;
    git: JailedGit;
}): PluginCommandResult;
export declare function applyGitSliceRevert(opts: {
    commandId: string;
    projectRoot: string;
    ref: string;
    pause?: {
        pause: () => {
            paused: boolean;
            state?: string;
            ack_ms?: number;
        };
    };
}): PluginCommandResult;
