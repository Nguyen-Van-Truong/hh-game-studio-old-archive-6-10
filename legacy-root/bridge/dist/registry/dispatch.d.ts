/** Registry lookup + param validation. Mutate stubs stay blocked; read/view may dispatch. */
import { DESCRIBE_KINDS, type ValidationResult } from "./types.js";
export declare function validateDescribeKindParams(params: Record<string, unknown>): ValidationResult | null;
export declare function acceptCommand(raw: unknown): ValidationResult;
export declare function exampleEnvelope(actionId: string, params: Record<string, unknown>, extras?: Record<string, unknown>): Record<string, unknown>;
export declare function describePositiveEnvelope(kind: (typeof DESCRIBE_KINDS)[number]): Record<string, unknown>;
