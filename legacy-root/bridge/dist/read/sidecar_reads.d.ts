import type { PauseGate } from "../policy/pause.js";
import type { SessionDescriptor } from "../session/descriptor.js";
import type { PluginCommandResult } from "../transport/plugin_rpc.js";
export interface SidecarReadInput {
    actionId: string;
    commandId: string;
    params: Record<string, unknown>;
    projectRoot: string;
    pause?: PauseGate;
    desc?: SessionDescriptor;
}
export declare function isSidecarOnlyAction(actionId: string, params: Record<string, unknown>): boolean;
export declare function trySidecarRead(input: SidecarReadInput): PluginCommandResult | undefined;
