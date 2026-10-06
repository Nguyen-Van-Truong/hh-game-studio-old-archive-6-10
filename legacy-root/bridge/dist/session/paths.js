import path from "node:path";
import { E, typedError } from "../registry/errors.js";
export const AGENT_DIR_NAME = "HHGodotAgent";
export const SESSIONS_DIR_NAME = "sessions";
export const DESCRIPTOR_FILE = "session.json";
export const LOCK_FILE = "sidecar.lock";
/** %LOCALAPPDATA%/HHGodotAgent — never cwd, never the git project. */
export function agentHome() {
    const local = process.env.LOCALAPPDATA;
    if (!local) {
        throw typedError(E.E_PATH, "LOCALAPPDATA is required for the session store", "LOCALAPPDATA");
    }
    return path.join(local, AGENT_DIR_NAME);
}
export function sessionsRoot(home = agentHome()) {
    return path.join(home, SESSIONS_DIR_NAME);
}
export function sessionDir(projectId, home = agentHome()) {
    if (!/^[0-9a-f]{32}$/.test(projectId)) {
        throw typedError(E.E_PROJECT_MISMATCH, "invalid project id", "project_id");
    }
    return path.join(sessionsRoot(home), projectId);
}
export function descriptorPath(projectId, home = agentHome()) {
    return path.join(sessionDir(projectId, home), DESCRIPTOR_FILE);
}
export function lockPath(projectId, home = agentHome()) {
    return path.join(sessionDir(projectId, home), LOCK_FILE);
}
export function isUnderAgentHome(target, home = agentHome()) {
    const rel = path.relative(path.resolve(home), path.resolve(target));
    return rel !== "" && !rel.startsWith("..") && !path.isAbsolute(rel);
}
