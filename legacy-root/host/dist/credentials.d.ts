export interface Credential {
    provider: string;
    source: "env" | "user-store";
    model: string;
    token: string;
    token_sha256: string;
}
/**
 * Credential comes from the OS/user store or HH_HOST_CREDENTIAL.
 * Never from the Godot project tree.
 */
export declare function resolveCredential(providerId: string): Credential;
