export declare const AGENT_DIR_NAME: "HHGodotAgent";
export declare const SESSIONS_DIR_NAME: "sessions";
export declare const DESCRIPTOR_FILE: "session.json";
export declare const LOCK_FILE: "sidecar.lock";
/** %LOCALAPPDATA%/HHGodotAgent — never cwd, never the git project. */
export declare function agentHome(): string;
export declare function sessionsRoot(home?: string): string;
export declare function sessionDir(projectId: string, home?: string): string;
export declare function descriptorPath(projectId: string, home?: string): string;
export declare function lockPath(projectId: string, home?: string): string;
export declare function isUnderAgentHome(target: string, home?: string): boolean;
