/** §5.1 envelope + result validation. Schema-only; binds no session/actor/policy. */
import { type CommandEnvelope, type JsonSchema, type TypedError } from "./types.js";
export declare const PRECONDITION_SCHEMA: JsonSchema;
export declare const PRESENTATION_SCHEMA: JsonSchema;
export declare function validateResult(value: unknown): TypedError | null;
export type EnvelopeOk = {
    ok: true;
    envelope: CommandEnvelope;
};
export type EnvelopeErr = {
    ok: false;
    error: TypedError;
};
export declare function parseEnvelope(raw: unknown): EnvelopeOk | EnvelopeErr;
