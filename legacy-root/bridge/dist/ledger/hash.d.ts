/** Deterministic JSON for request hashing. Sorted object keys; arrays keep order. */
export declare function stableStringify(value: unknown): string;
export interface RequestHashInput {
    command_id: string;
    method: string;
    action: string;
    params: unknown;
    precondition?: unknown;
    presentation?: unknown;
    action_version?: unknown;
}
/** Canonical request hash. Bound actor/project/policy are compared separately. */
export declare function canonicalRequestHash(input: RequestHashInput): string;
