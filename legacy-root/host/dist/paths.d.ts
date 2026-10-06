export declare const AGENT_DIR_NAME: "HHGodotAgent";
export declare const HOSTS_DIR_NAME: "hosts";
export declare const CREDENTIALS_DIR_NAME: "credentials";
export declare const STATE_FILE: "state.json";
export declare const SESSION_MS: number;
/** %LOCALAPPDATA%/HHGodotAgent — never cwd, never the Godot project tree. */
export declare function agentHome(): string;
export declare function hostsRoot(home?: string): string;
export declare function hostDir(sessionId: string, home?: string): string;
export declare function statePath(sessionId: string, home?: string): string;
export declare function credentialsDir(home?: string): string;
export declare function credentialPath(providerId: string, home?: string): string;
export declare function isUnderAgentHome(target: string, home?: string): boolean;
