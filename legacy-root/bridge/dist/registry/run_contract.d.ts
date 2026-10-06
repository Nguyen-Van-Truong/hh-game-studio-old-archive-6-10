/** Execute the contract matrix and envelope guards. No Godot. */
export interface ContractReport {
    ok: boolean;
    actions: number;
    cases: number;
    failed: number;
    errors: string[];
}
export declare function runContract(): ContractReport;
