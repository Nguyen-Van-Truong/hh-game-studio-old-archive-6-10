import { VARIANT_SCHEMA_VERSION } from "./types.js";
export declare const VARIANT_TYPES: readonly ["bool", "int", "float", "string", "Vector2", "Vector2i", "Vector3", "Rect2", "Transform2D", "Transform3D", "Color", "NodePath", "RID", "Resource", "Array", "Dictionary", "TypedArray"];
export type VariantType = (typeof VARIANT_TYPES)[number];
export interface EncodedVariant {
    schema: typeof VARIANT_SCHEMA_VERSION;
    type: VariantType;
    value: unknown;
}
export type VariantDecode = {
    ok: true;
    value: EncodedVariant;
} | {
    ok: false;
    error: {
        code: string;
        message: string;
        path: string;
    };
};
export declare function decodeVariant(raw: unknown, path?: string): VariantDecode;
export declare function encodeVariant(kind: VariantType, value: unknown, path?: string): VariantDecode;
export declare function variantSchemaDoc(): Record<string, unknown>;
