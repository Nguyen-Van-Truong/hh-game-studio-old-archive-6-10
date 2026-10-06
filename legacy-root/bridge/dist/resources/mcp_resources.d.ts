import { type SessionDescriptor } from "../session/descriptor.js";
import type { PluginCommandResult } from "../transport/plugin_rpc.js";
export declare const RESOURCE_URIS: readonly ["project://summary", "editor://state", "capability://matrix", "session://state"];
export type ResourceUri = (typeof RESOURCE_URIS)[number];
export interface McpResource {
    uri: ResourceUri;
    name: string;
    description: string;
    mimeType: "application/json";
}
export declare function listResources(): McpResource[];
export declare function capabilityMatrix(): Record<string, unknown>;
export declare function projectSummary(args: {
    descriptor: SessionDescriptor;
    inspect?: Record<string, unknown>;
}): Record<string, unknown>;
export declare function editorStateFromResult(result: PluginCommandResult | undefined): Record<string, unknown>;
export declare function resourceBody(uri: string, body: unknown, secret?: string): {
    uri: string;
    mimeType: "application/json";
    text: string;
};
export declare function isResourceUri(uri: string): uri is ResourceUri;
