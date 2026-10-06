import { E, typedError } from "../registry/errors.js";
export const PLUGIN_NOOP_METHOD = "hh.plugin";
export const PLUGIN_NOOP_ACTION = "noop";
export function isNoopEnvelope(env) {
    return env.method === PLUGIN_NOOP_METHOD && env.action === PLUGIN_NOOP_ACTION;
}
export const PLUGIN_READBACK_TYPE = "readback";
export const PLUGIN_READBACK_RESULT_TYPE = "readback_result";
export function emptyReadback(commandId) {
    return {
        type: PLUGIN_READBACK_RESULT_TYPE,
        command_id: commandId,
        found: false,
        ok: false,
        postcondition: { verified: false, checks: [] },
    };
}
export function parsePluginReadback(raw) {
    if (!isRecord(raw)) {
        return null;
    }
    if (raw.type !== PLUGIN_READBACK_RESULT_TYPE) {
        return null;
    }
    if (typeof raw.command_id !== "string" || raw.command_id.length < 1) {
        return null;
    }
    const postRaw = raw.postcondition;
    let postcondition = { verified: false, checks: [] };
    if (isRecord(postRaw)) {
        const checks = Array.isArray(postRaw.checks)
            ? postRaw.checks.filter((c) => typeof c === "string")
            : [];
        postcondition = { verified: postRaw.verified === true, checks };
    }
    return {
        type: PLUGIN_READBACK_RESULT_TYPE,
        command_id: raw.command_id,
        found: raw.found === true,
        ok: raw.ok === true,
        postcondition,
    };
}
export function unverifiedResult(commandId, message) {
    return {
        type: "result",
        ok: false,
        command_id: commandId,
        changed: false,
        postcondition: { verified: false, checks: [] },
        error: typedError(E.E_UNVERIFIED, message, ""),
    };
}
export function busyResult(commandId, message) {
    return {
        type: "result",
        ok: false,
        command_id: commandId,
        changed: false,
        postcondition: { verified: false, checks: [] },
        error: typedError(E.E_BUSY, message, ""),
    };
}
function isRecord(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
}
export function parsePluginResult(raw) {
    if (!isRecord(raw)) {
        return null;
    }
    if (raw.type !== "result") {
        return null;
    }
    if (typeof raw.command_id !== "string" || raw.command_id.length < 1) {
        return null;
    }
    const postRaw = raw.postcondition;
    let postcondition = { verified: false, checks: [] };
    if (isRecord(postRaw)) {
        const checks = Array.isArray(postRaw.checks)
            ? postRaw.checks.filter((c) => typeof c === "string")
            : [];
        postcondition = { verified: postRaw.verified === true, checks };
    }
    const result = {
        type: "result",
        ok: raw.ok === true,
        command_id: raw.command_id,
        changed: raw.changed === true,
        postcondition,
    };
    if (isRecord(raw.error) && typeof raw.error.code === "string") {
        result.error = {
            code: raw.error.code,
            message: typeof raw.error.message === "string" ? raw.error.message : "",
            path: typeof raw.error.path === "string" ? raw.error.path : "",
        };
    }
    if (isRecord(raw.after)) {
        result.after = raw.after;
    }
    if (isRecord(raw.before)) {
        result.before = raw.before;
    }
    if (typeof raw.undo_action === "string") {
        result.undo_action = raw.undo_action;
    }
    if (Array.isArray(raw.warnings)) {
        result.warnings = raw.warnings.filter((item) => typeof item === "string");
    }
    if (Array.isArray(raw.evidence)) {
        result.evidence = raw.evidence.filter((item) => typeof item === "string");
    }
    return result;
}
export function guardPaperSuccess(result, envelope) {
    if (result.ok &&
        result.postcondition.verified &&
        result.postcondition.checks.length === 0 &&
        !isNoopEnvelope(envelope)) {
        return unverifiedResult(result.command_id, "verified:true with empty checks is a paper success");
    }
    return result;
}
