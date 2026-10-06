/** Project-scoped git jail. Never walk up to a parent (studio) repo. */
export declare const GIT_EVIDENCE_DIR = "r7w3";
export declare const GIT_CKPT_DIR = "r7w3/ckpts";
export declare const LFS_THRESHOLD_BYTES = 65536;
export declare const LFS_TYPES: Set<string>;
export interface JailedGit {
    worktree: string;
    gitDir: string;
    rel: string;
}
export interface JailGitErr {
    ok: false;
    error: {
        code: string;
        message: string;
        path: string;
    };
}
export interface GitRun {
    status: number;
    stdout: string;
    stderr: string;
}
export declare function posixRel(rel: string): string;
export declare function underRoot(root: string, candidate: string): boolean;
export declare function assertSafeGitArgv(argv: readonly string[]): void;
export declare function resolveJailedGit(projectRoot: string, repoRel?: string): {
    ok: true;
    git: JailedGit;
} | JailGitErr;
export declare function findJailedGitFromPaths(projectRoot: string, paths: readonly string[], repoRel?: string): {
    ok: true;
    git: JailedGit;
} | JailGitErr;
export declare function runJailedGit(git: JailedGit, argv: readonly string[], timeoutMs?: number): GitRun;
export declare function verifyToplevel(git: JailedGit): boolean;
export declare function jailGitEvidence(projectRoot: string, rel: string): {
    ok: true;
    abs: string;
    rel: string;
} | JailGitErr;
export declare function runIdOk(runId: string): boolean;
export declare function projectSlugOk(slug: string): boolean;
export declare function agentBranch(project: string, runId: string): string;
