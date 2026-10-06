/** Shared JSON Schema fragments. Command params always use additionalProperties: false. */
import type { JsonSchema } from "./types.js";
export declare function obj(required: string[], properties: Record<string, JsonSchema>): JsonSchema;
export declare const RES_PATH: JsonSchema;
export declare const NODE_PATH: JsonSchema;
export declare const IDENT: JsonSchema;
export declare const PROP_PATH: JsonSchema;
export declare const ACTION_ID: JsonSchema;
export declare const DETAIL: JsonSchema;
export declare const INDEX: JsonSchema;
export declare const LIMIT: JsonSchema;
export declare const OFFSET: JsonSchema;
export declare const REVIEW_REL: JsonSchema;
export declare const CURSOR: JsonSchema;
export declare const PREFIX: JsonSchema;
export declare const VARIANT: JsonSchema;
export declare const BOOL: JsonSchema;
export declare const TEXT: JsonSchema;
/** Read-only external ingest source (A8 import-grant). Not a res:// dest. */
export declare const OS_SOURCE: JsonSchema;
/** Dedicated cap for script source / find / replace. TEXT stays short for other fields. */
export declare const SCRIPT_TEXT: JsonSchema;
/** PROJECT_BRIEF markdown. Longer than TEXT; shorter than a full script. */
export declare const BRIEF_TEXT: JsonSchema;
export declare const JOB_ID: JsonSchema;
export declare const RUN_ID: JsonSchema;
export declare const HASH: JsonSchema;
export declare const UID_TEXT: JsonSchema;
export declare function exampleVariantInt(value?: number): Record<string, unknown>;
export declare function exampleVariantBool(value?: boolean): Record<string, unknown>;
export declare function exampleVariantVec2(x?: number, y?: number): Record<string, unknown>;
export declare const DESCRIBE_KIND_SCHEMA: JsonSchema;
export declare const DESCRIBE_INPUT: JsonSchema;
