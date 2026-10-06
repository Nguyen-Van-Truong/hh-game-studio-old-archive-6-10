/** Typed host errors. E_EXTERNAL lives here so the bridge registry is not churned. */
export const E = {
    E_EXTERNAL: "E_EXTERNAL",
    E_POLICY: "E_POLICY",
    E_CANCELLED: "E_CANCELLED",
    E_TIMEOUT: "E_TIMEOUT",
    E_BUSY: "E_BUSY",
    E_PATH: "E_PATH",
    E_INVALID_COMMAND_ID: "E_INVALID_COMMAND_ID",
    E_UNVERIFIED: "E_UNVERIFIED",
};
export function typedError(code, message, path = "") {
    return { code, message, path };
}
export class HostError extends Error {
    code;
    path;
    constructor(code, message, path) {
        super(message);
        this.name = "HostError";
        this.code = code;
        this.path = path;
    }
    static from(err) {
        return new HostError(err.code, err.message, err.path);
    }
    typed() {
        return typedError(this.code, this.message, this.path);
    }
}
export function isTypedError(value) {
    if (value === null || typeof value !== "object") {
        return false;
    }
    const rec = value;
    return (typeof rec.code === "string" &&
        typeof rec.message === "string" &&
        typeof rec.path === "string");
}
