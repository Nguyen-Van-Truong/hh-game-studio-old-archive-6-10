import path from "node:path";
import { E, HostError } from "./errors.js";
export const AGENT_DIR_NAME = "HHGodotAgent";
export const HOSTS_DIR_NAME = "hosts";
export const CREDENTIALS_DIR_NAME = "credentials";
export const STATE_FILE = "state.json";
export const SESSION_MS = 90 * 60 * 1000;
/** %LOCALAPPDATA%/HHGodotAgent — never cwd, never the Godot project tree. */
export function agentHome() {
    const local = process.env.LOCALAPPDATA;
    if (!local) {
        throw new HostError(E.E_PATH, "LOCALAPPDATA is required for the host store", "LOCALAPPDATA");
    }
    return path.join(local, AGENT_DIR_NAME);
}
export function hostsRoot(home = agentHome()) {
    return path.join(home, HOSTS_DIR_NAME);
}
export function hostDir(sessionId, home = agentHome()) {
    return path.join(hostsRoot(home), sessionId);
}
export function statePath(sessionId, home = agentHome()) {
    return path.join(hostDir(sessionId, home), STATE_FILE);
}
export function credentialsDir(home = agentHome()) {
    return path.join(home, CREDENTIALS_DIR_NAME);
}
export function credentialPath(providerId, home = agentHome()) {
    return path.join(credentialsDir(home), `${providerId}.json`);
}
export function isUnderAgentHome(target, home = agentHome()) {
    const rel = path.relative(path.resolve(home), path.resolve(target));
    return rel !== "" && !rel.startsWith("..") && !path.isAbsolute(rel);
}
