/** Shared JSON Schema fragments. Command params always use additionalProperties: false. */
import { DESCRIBE_KINDS, VARIANT_SCHEMA_VERSION } from "./types.js";
export function obj(required, properties) {
    return {
        type: "object",
        additionalProperties: false,
        required,
        properties,
    };
}
export const RES_PATH = {
    type: "string",
    minLength: 6,
    maxLength: 256,
    pattern: "^res://[^\\s]+$",
};
export const NODE_PATH = {
    type: "string",
    minLength: 1,
    maxLength: 256,
    pattern: "^[A-Za-z_./%:@][A-Za-z0-9_./%:@-]*$",
};
export const IDENT = {
    type: "string",
    minLength: 1,
    maxLength: 128,
    pattern: "^[A-Za-z_][A-Za-z0-9_]*$",
};
export const PROP_PATH = {
    type: "string",
    minLength: 1,
    maxLength: 256,
    pattern: "^[A-Za-z_][A-Za-z0-9_]*(?:[/:][A-Za-z_][A-Za-z0-9_]*)*$",
};
export const ACTION_ID = {
    type: "string",
    minLength: 3,
    maxLength: 128,
    pattern: "^[a-z]+\\.[a-z_]+$",
};
export const DETAIL = {
    type: "string",
    enum: ["short", "full"],
};
export const INDEX = {
    type: "integer",
    minimum: 0,
    maximum: 4096,
};
export const LIMIT = {
    type: "integer",
    minimum: 1,
    maximum: 100,
};
export const OFFSET = {
    type: "integer",
    minimum: 0,
    maximum: 100000,
};
export const REVIEW_REL = {
    type: "string",
    minLength: 1,
    maxLength: 256,
    pattern: "^[A-Za-z0-9][A-Za-z0-9_./-]*$",
};
export const CURSOR = {
    type: "string",
    minLength: 1,
    maxLength: 64,
    pattern: "^[0-9A-Za-z_.:-]+$",
};
export const PREFIX = {
    type: "string",
    minLength: 1,
    maxLength: 128,
    pattern: "^[A-Za-z_][A-Za-z0-9_]*$",
};
export const VARIANT = {
    hhCodec: "variant",
};
export const BOOL = { type: "boolean" };
export const TEXT = {
    type: "string",
    minLength: 1,
    maxLength: 4000,
};
/** Read-only external ingest source (A8 import-grant). Not a res:// dest. */
export const OS_SOURCE = {
    type: "string",
    minLength: 1,
    maxLength: 512,
};
/** Dedicated cap for script source / find / replace. TEXT stays short for other fields. */
export const SCRIPT_TEXT = {
    type: "string",
    minLength: 1,
    maxLength: 262144,
};
/** PROJECT_BRIEF markdown. Longer than TEXT; shorter than a full script. */
export const BRIEF_TEXT = {
    type: "string",
    minLength: 1,
    maxLength: 32000,
};
export const JOB_ID = {
    type: "string",
    minLength: 1,
    maxLength: 64,
    pattern: "^[A-Za-z0-9_-]+$",
};
export const RUN_ID = {
    type: "string",
    minLength: 26,
    maxLength: 26,
    pattern: "^[0-7][0-9A-HJKMNPQRSTVWXYZ]{25}$",
};
export const HASH = {
    type: "string",
    minLength: 8,
    maxLength: 128,
    pattern: "^[A-Fa-f0-9]+$",
};
export const UID_TEXT = {
    type: "string",
    minLength: 7,
    maxLength: 128,
    pattern: "^uid://[A-Za-z0-9]+$",
};
export function exampleVariantInt(value = 1) {
    return {
        schema: VARIANT_SCHEMA_VERSION,
        type: "int",
        value,
    };
}
export function exampleVariantBool(value = true) {
    return {
        schema: VARIANT_SCHEMA_VERSION,
        type: "bool",
        value,
    };
}
export function exampleVariantVec2(x = 0, y = 0) {
    return {
        schema: VARIANT_SCHEMA_VERSION,
        type: "Vector2",
        value: { x, y },
    };
}
export const DESCRIBE_KIND_SCHEMA = {
    type: "string",
    enum: [...DESCRIBE_KINDS],
};
export const DESCRIBE_INPUT = obj(["kind"], {
    kind: DESCRIBE_KIND_SCHEMA,
    class_name: IDENT,
    property_name: IDENT,
    method_name: IDENT,
    action_id: ACTION_ID,
    limit: LIMIT,
    cursor: CURSOR,
    prefix: PREFIX,
});
