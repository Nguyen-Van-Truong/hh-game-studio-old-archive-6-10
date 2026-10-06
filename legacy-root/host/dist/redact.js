import { createHash } from "node:crypto";
const SECRET_KEYS = new Set([
    "token",
    "secret",
    "credential",
    "api_key",
    "apikey",
    "authorization",
    "password",
    "hh_host_credential",
]);
export function sha256Hex(value) {
    return createHash("sha256").update(value, "utf8").digest("hex");
}
export function redactSecrets(text, secrets) {
    let out = text;
    for (const secret of secrets) {
        if (secret.length >= 8 && out.includes(secret)) {
            out = out.split(secret).join("[redacted]");
        }
    }
    return out;
}
export function stripSecrets(value) {
    if (Array.isArray(value)) {
        return value.map((item) => stripSecrets(item));
    }
    if (value !== null && typeof value === "object") {
        const out = {};
        for (const [key, item] of Object.entries(value)) {
            if (SECRET_KEYS.has(key.toLowerCase())) {
                continue;
            }
            out[key] = stripSecrets(item);
        }
        return out;
    }
    return value;
}
