import { E, typedError } from "../registry/errors.js";
import { PROTOCOL } from "../registry/types.js";
import { tokensEqual } from "../session/token.js";
export function parseHello(raw) {
    if (!raw || typeof raw !== "object") {
        return fail(E.E_INVALID_ENVELOPE, "hello must be an object", "");
    }
    const rec = raw;
    if (rec.type !== "hello") {
        return fail(E.E_INVALID_ENVELOPE, "first frame must be hello", "type");
    }
    if (typeof rec.protocol !== "string") {
        return fail(E.E_PROTOCOL_VERSION, "protocol required", "protocol");
    }
    if (typeof rec.project_id !== "string") {
        return fail(E.E_PROJECT_MISMATCH, "project_id required", "project_id");
    }
    if (typeof rec.token !== "string") {
        return fail(E.E_AUTH, "session rejected", "token");
    }
    return {
        type: "hello",
        protocol: rec.protocol,
        project_id: rec.project_id,
        token: rec.token,
    };
}
export function evaluateHello(hello, expected) {
    if (hello.protocol !== expected.protocol) {
        return fail(E.E_PROTOCOL_VERSION, "protocol mismatch", "protocol");
    }
    if (hello.project_id !== expected.projectId) {
        return fail(E.E_PROJECT_MISMATCH, "project mismatch", "project_id");
    }
    if (!tokensEqual(hello.token, expected.token)) {
        return fail(E.E_AUTH, "session rejected", "token");
    }
    return {
        ok: true,
        type: "hello_ok",
        protocol: PROTOCOL,
        project_id: expected.projectId,
        session_id: expected.sessionId,
    };
}
function fail(code, message, path) {
    return { ok: false, type: "hello_err", error: typedError(code, message, path) };
}
