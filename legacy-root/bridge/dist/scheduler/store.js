/** Atomic persist for scheduler records. Jail: r7w4/ only, no .. / addons / .hh-agent. */
import { createHash } from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { jailProjectPath } from "../policy/jail.js";
import { contentHash } from "../policy/leases.js";
import { E, typedError } from "../registry/errors.js";
import { EMPTY_SHA256, SCHED_DIR, SCHED_SCHEMA } from "./types.js";
export function jobIdOk(jobId) {
    return /^[A-Za-z0-9_-]{1,64}$/.test(jobId);
}
export function jailSchedRel(projectRoot, rel) {
    const p = rel.replace(/\\/g, "/").replace(/^\/+/, "");
    if (p.includes("..") || p.includes("addons/") || p.startsWith(".hh-agent") || p.includes("/.hh-agent")) {
        return { ok: false, code: E.E_PATH, message: "scheduler path escapes jail", path: rel };
    }
    if (!p.startsWith(`${SCHED_DIR}/`)) {
        return { ok: false, code: E.E_PATH, message: "scheduler writes only under r7w4/", path: rel };
    }
    const jailed = jailProjectPath(projectRoot, p, { forWrite: true });
    if (!jailed.ok) {
        return { ok: false, code: jailed.error.code, message: jailed.error.message, path: jailed.error.path };
    }
    return { ok: true, abs: jailed.abs, rel: jailed.rel };
}
export function atomicWriteUtf8(absPath, text) {
    fs.mkdirSync(path.dirname(absPath), { recursive: true });
    const tmp = `${absPath}.tmp`;
    fs.writeFileSync(tmp, text, "utf8");
    try {
        fs.unlinkSync(absPath);
    }
    catch {
        /* dest may not exist */
    }
    try {
        fs.renameSync(tmp, absPath);
        return true;
    }
    catch {
        return false;
    }
}
export function stateRel(jobId) {
    return `${SCHED_DIR}/${jobId}/state.json`;
}
export function progressRel(jobId) {
    return `${SCHED_DIR}/${jobId}/progress.json`;
}
export function generatedRel(jobId, name) {
    return `${SCHED_DIR}/${jobId}/generated/${name}`;
}
export function registryRel(jobId, name) {
    return `${SCHED_DIR}/${jobId}/registry/${name}`;
}
export function coordinatorOwnedRel(rel) {
    const p = rel.replace(/\\/g, "/");
    return (/\/generated\//.test(p) ||
        /\/registry\//.test(p) ||
        p.endsWith("/progress.json") ||
        p.includes("/progress/"));
}
export function fileDigest(absPath) {
    const raw = contentHash(absPath);
    return raw === "missing" ? EMPTY_SHA256 : raw;
}
export function textDigest(text) {
    return createHash("sha256").update(text).digest("hex");
}
export function loadRecord(projectRoot, jobId) {
    if (!jobIdOk(jobId)) {
        return undefined;
    }
    const jailed = jailSchedRel(projectRoot, stateRel(jobId));
    if (!jailed.ok || !fs.existsSync(jailed.abs)) {
        return undefined;
    }
    try {
        const parsed = JSON.parse(fs.readFileSync(jailed.abs, "utf8"));
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
            return undefined;
        }
        const rec = parsed;
        if (rec.schema !== SCHED_SCHEMA || rec.job_id !== jobId) {
            return undefined;
        }
        return rec;
    }
    catch {
        return undefined;
    }
}
export function saveRecord(projectRoot, rec) {
    if (!jobIdOk(rec.job_id)) {
        return { ok: false, code: E.E_PATH, message: "invalid job_id", path: "job_id" };
    }
    const jailed = jailSchedRel(projectRoot, stateRel(rec.job_id));
    if (!jailed.ok) {
        return { ok: false, code: jailed.code, message: jailed.message, path: jailed.path };
    }
    if (!atomicWriteUtf8(jailed.abs, `${JSON.stringify(rec, null, 2)}\n`)) {
        return { ok: false, code: E.E_UNVERIFIED, message: "scheduler persist failed", path: jailed.rel };
    }
    const progress = jailSchedRel(projectRoot, progressRel(rec.job_id));
    if (progress.ok) {
        atomicWriteUtf8(progress.abs, `${JSON.stringify(rec.progress, null, 2)}\n`);
    }
    return { ok: true };
}
export function writeOwned(projectRoot, rel, body) {
    const jailed = jailSchedRel(projectRoot, rel);
    if (!jailed.ok) {
        return { ok: false, code: jailed.code, message: jailed.message, path: jailed.path };
    }
    const text = typeof body === "string" ? body : `${JSON.stringify(body, null, 2)}\n`;
    if (!atomicWriteUtf8(jailed.abs, text)) {
        return { ok: false, code: E.E_UNVERIFIED, message: "scheduler write failed", path: jailed.rel };
    }
    return { ok: true, rel: jailed.rel };
}
export function listRecords(projectRoot) {
    const root = path.join(projectRoot, SCHED_DIR);
    if (!fs.existsSync(root) || !fs.statSync(root).isDirectory()) {
        return [];
    }
    const out = [];
    for (const name of fs.readdirSync(root)) {
        const rec = loadRecord(projectRoot, name);
        if (rec) {
            out.push(rec);
        }
    }
    return out;
}
export function newRecord(jobId, now, fixture = "") {
    return {
        schema: SCHED_SCHEMA,
        job_id: jobId,
        state: "idle",
        started_at_ms: now,
        heartbeat_at_ms: now,
        fixture,
        workers: [],
        proposals: [],
        progress: { owner: "coordinator", job_id: jobId },
        generated: { owner: "coordinator" },
        registry: { owner: "coordinator" },
        lane: [],
        overlap: false,
        serial_ms: 0,
        parallel_ms: 0,
        blocked_reason: "",
    };
}
export function typedFail(commandId, code, message, pathName, after) {
    return {
        type: "result",
        ok: false,
        command_id: commandId,
        changed: false,
        postcondition: { verified: false, checks: [] },
        error: typedError(code, message, pathName),
        ...(after ? { after } : {}),
    };
}
