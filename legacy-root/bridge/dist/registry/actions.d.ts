/**
 * Live ActionDef catalog — one row per §5.2 verb. Schema-only; no editor handlers.
 */
import { DESCRIBE_KINDS, type ActionDef, type JsonSchema, type Policy, type SideEffect, type UndoStrategy } from "./types.js";
export interface ActionSpec {
    summary: string;
    side_effect: SideEffect;
    undo: UndoStrategy;
    required_policy: Policy;
    timeout_ms?: number;
    cancellable?: boolean;
    checkpoint_required?: boolean;
    input: JsonSchema;
    example: Record<string, unknown>;
    postcondition: string;
    extra_errors?: readonly string[];
}
export declare function loadActionDefs(): ActionDef[];
export declare function describeExample(kind: (typeof DESCRIBE_KINDS)[number]): Record<string, unknown>;
export declare function describeMissing(kind: (typeof DESCRIBE_KINDS)[number]): Record<string, unknown>;
export declare function describeWrongType(kind: (typeof DESCRIBE_KINDS)[number]): Record<string, unknown>;
export declare function describeOutOfBounds(kind: (typeof DESCRIBE_KINDS)[number]): Record<string, unknown>;
