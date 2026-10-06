/** Contract cases: every action × missing / unknown / type / bounds + 1 positive. */
export type MatrixExpect = "accept" | string;
export interface ContractCase {
    id: string;
    action_id: string;
    kind: string;
    lane: "positive" | "missing" | "unknown" | "type" | "bounds";
    params: Record<string, unknown>;
    expect: MatrixExpect;
}
export declare function buildContractMatrix(): ContractCase[];
export declare function matrixStats(cases: ContractCase[]): {
    actions: number;
    positives: number;
    missing: number;
    unknown: number;
    type: number;
    bounds: number;
};
