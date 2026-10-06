/** One-shot EDIT destructive confirmation bound to actor + request hash + revision. */
export declare function approvalToken(actorId: string, requestHash: string, revision: string): string;
export declare function projectRevision(projectRoot: string): string;
export declare class ApprovalBinder {
    private unused;
    private readonly storePath;
    constructor(projectRoot?: string);
    issue(actorId: string, requestHash: string, revision: string): string;
    consume(actorId: string, requestHash: string, revision: string, token: string): boolean;
    private key;
    private reload;
    private persist;
}
