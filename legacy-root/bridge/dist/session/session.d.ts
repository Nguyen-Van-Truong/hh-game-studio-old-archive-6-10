import { type CommandLedger } from "../ledger/store.js";
import { PauseGate } from "../policy/pause.js";
import type { PolicyServices } from "../policy/engine.js";
import { type PluginTransport } from "../transport/websocket.js";
import { type SessionDescriptor } from "./descriptor.js";
import { type SessionLog } from "./log.js";
import { type DiscoveredProject } from "./project.js";
import { ProcessSupervisor } from "./supervisor.js";
export interface SidecarHandle {
    project: DiscoveredProject;
    descriptor: SessionDescriptor;
    transport: PluginTransport;
    supervisor: ProcessSupervisor;
    log: SessionLog;
    ledger: CommandLedger;
    actorId: string;
    policy: string;
    pause: PauseGate;
    policyServices: PolicyServices;
    close: () => Promise<void>;
}
export declare function startSidecar(projectInput: string): Promise<SidecarHandle>;
