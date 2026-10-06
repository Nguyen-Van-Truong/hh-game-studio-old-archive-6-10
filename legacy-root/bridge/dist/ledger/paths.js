import path from "node:path";
import { E, typedError } from "../registry/errors.js";
import { agentHome } from "../session/paths.js";
export const PROJECTS_DIR_NAME = "projects";
export const LEDGER_FILE = "ledger.sqlite";
export function assertProjectId(projectId) {
    if (!/^[0-9a-f]{32}$/.test(projectId)) {
        throw typedError(E.E_PROJECT_MISMATCH, "invalid project id", "project_id");
    }
    return projectId;
}
/** %LOCALAPPDATA%/HHGodotAgent/projects/<project_id> — never the git project or .godot/. */
export function projectStoreDir(projectId, home = agentHome()) {
    return path.join(home, PROJECTS_DIR_NAME, assertProjectId(projectId));
}
export function ledgerFilePath(projectId, home = agentHome()) {
    return path.join(projectStoreDir(projectId, home), LEDGER_FILE);
}
/** Bound actor is project-stable. Session id must not be part of idempotency identity. */
export function durableActorId(projectId) {
    return `project:${assertProjectId(projectId)}`;
}
export function isUnderAgentHome(target, home = agentHome()) {
    const rel = path.relative(path.resolve(home), path.resolve(target));
    return rel !== "" && !rel.startsWith("..") && !path.isAbsolute(rel);
}
