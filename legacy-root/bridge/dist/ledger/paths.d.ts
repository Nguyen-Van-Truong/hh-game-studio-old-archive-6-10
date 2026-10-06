export declare const PROJECTS_DIR_NAME: "projects";
export declare const LEDGER_FILE: "ledger.sqlite";
export declare function assertProjectId(projectId: string): string;
/** %LOCALAPPDATA%/HHGodotAgent/projects/<project_id> — never the git project or .godot/. */
export declare function projectStoreDir(projectId: string, home?: string): string;
export declare function ledgerFilePath(projectId: string, home?: string): string;
/** Bound actor is project-stable. Session id must not be part of idempotency identity. */
export declare function durableActorId(projectId: string): string;
export declare function isUnderAgentHome(target: string, home?: string): boolean;
