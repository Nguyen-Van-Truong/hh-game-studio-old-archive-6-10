import type { JsonSchema } from "./types.js";
export interface SchemaIssue {
    code: string;
    message: string;
    path: string;
}
export declare function validateSchema(schema: JsonSchema, value: unknown, path?: string): SchemaIssue | null;
