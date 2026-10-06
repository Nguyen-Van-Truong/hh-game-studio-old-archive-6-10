import fs from "node:fs";
import path from "node:path";
import { PROTOCOL } from "../registry/types.js";
import { E, typedError } from "../registry/errors.js";
import { applyCurrentUserAcl } from "./acl.js";
import { DESCRIPTOR_FILE, LOCK_FILE, descriptorPath, sessionDir, sessionsRoot, } from "./paths.js";
import { pidAlive } from "./supervisor.js";
import { isSessionToken } from "./token.js";
export function publicDescriptorView(desc) {
    return {
        protocol: desc.protocol,
        project_id: desc.project_id,
        host: desc.host,
        port: desc.port,
        pid: desc.pid,
        started_at: desc.started_at,
        token: "[redacted]",
    };
}
function unlinkQuiet(file) {
    try {
        fs.unlinkSync(file);
    }
    catch {
        /* missing is fine */
    }
}
export function cleanupStaleSessions(home) {
    const root = sessionsRoot(home);
    if (!fs.existsSync(root)) {
        return;
    }
    for (const name of fs.readdirSync(root)) {
        const dir = path.join(root, name);
        let stat;
        try {
            stat = fs.statSync(dir);
        }
        catch {
            continue;
        }
        if (!stat.isDirectory()) {
            continue;
        }
        const lock = path.join(dir, LOCK_FILE);
        if (!fs.existsSync(lock)) {
            continue;
        }
        let pid = 0;
        try {
            const raw = JSON.parse(fs.readFileSync(lock, "utf8"));
            if (raw && typeof raw === "object" && "pid" in raw && typeof raw.pid === "number") {
                pid = raw.pid;
            }
        }
        catch {
            pid = 0;
        }
        if (!pidAlive(pid)) {
            unlinkQuiet(path.join(dir, DESCRIPTOR_FILE));
            unlinkQuiet(lock);
        }
    }
}
export function acquireProjectLock(projectId, supervisor, home) {
    const dir = sessionDir(projectId, home);
    fs.mkdirSync(dir, { recursive: true });
    applyCurrentUserAcl(dir, supervisor);
    const lock = path.join(dir, LOCK_FILE);
    if (fs.existsSync(lock)) {
        let pid = 0;
        try {
            const raw = JSON.parse(fs.readFileSync(lock, "utf8"));
            if (raw && typeof raw === "object" && "pid" in raw && typeof raw.pid === "number") {
                pid = raw.pid;
            }
        }
        catch {
            pid = 0;
        }
        if (pidAlive(pid) && pid !== process.pid) {
            throw typedError(E.E_BUSY, "one sidecar per project session", "lock");
        }
        unlinkQuiet(path.join(dir, DESCRIPTOR_FILE));
        unlinkQuiet(lock);
    }
    fs.writeFileSync(lock, `${JSON.stringify({ pid: process.pid })}\n`, { encoding: "utf8", flag: "wx" });
}
export function writeDescriptor(desc, supervisor, home) {
    if (!isSessionToken(desc.token)) {
        throw typedError(E.E_AUTH, "refusing to persist a non-256-bit token", "token");
    }
    if (desc.host !== "127.0.0.1") {
        throw typedError(E.E_BIND, "descriptor host must be loopback", "host");
    }
    const dir = sessionDir(desc.project_id, home);
    fs.mkdirSync(dir, { recursive: true });
    applyCurrentUserAcl(dir, supervisor);
    const dest = descriptorPath(desc.project_id, home);
    const tmp = `${dest}.tmp`;
    fs.writeFileSync(tmp, `${JSON.stringify(desc)}\n`, { encoding: "utf8" });
    fs.renameSync(tmp, dest);
    try {
        applyCurrentUserAcl(dest, supervisor);
    }
    catch (err) {
        unlinkQuiet(dest);
        throw err;
    }
    return dest;
}
export function readDescriptor(projectId, home) {
    const dest = descriptorPath(projectId, home);
    const raw = JSON.parse(fs.readFileSync(dest, "utf8"));
    if (!raw || typeof raw !== "object") {
        throw typedError(E.E_AUTH, "invalid session descriptor", "descriptor");
    }
    const rec = raw;
    if (rec.protocol !== PROTOCOL) {
        throw typedError(E.E_PROTOCOL_VERSION, "descriptor protocol mismatch", "protocol");
    }
    if (typeof rec.token !== "string" || !isSessionToken(rec.token)) {
        throw typedError(E.E_AUTH, "descriptor token missing", "token");
    }
    if (rec.host !== "127.0.0.1") {
        throw typedError(E.E_BIND, "descriptor host is not loopback", "host");
    }
    if (typeof rec.port !== "number" || rec.port <= 0) {
        throw typedError(E.E_BIND, "descriptor port invalid", "port");
    }
    return raw;
}
export function removeSessionFiles(projectId, home) {
    const dir = sessionDir(projectId, home);
    unlinkQuiet(path.join(dir, DESCRIPTOR_FILE));
    unlinkQuiet(path.join(dir, LOCK_FILE));
    unlinkQuiet(path.join(dir, `${DESCRIPTOR_FILE}.tmp`));
}
