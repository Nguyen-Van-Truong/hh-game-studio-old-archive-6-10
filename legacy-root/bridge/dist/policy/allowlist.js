/** Process and network allowlist. No arbitrary shell; argv arrays only. */
import { E, typedError } from "../registry/errors.js";
export const PROCESS_ALLOWLIST = ["godot", "gut", "exporter", "git", "icacls"];
const PROCESS_ALIASES = {
    godot: "godot",
    godot_console: "godot",
    godot_headless: "godot",
    gut: "gut",
    gut_cli: "gut",
    exporter: "exporter",
    godot_export: "exporter",
    git: "git",
    icacls: "icacls",
};
const LOOPBACK = new Set(["127.0.0.1", "::1", "localhost"]);
function baseName(file) {
    const norm = file.replace(/\\/g, "/");
    const cut = norm.lastIndexOf("/");
    const name = (cut >= 0 ? norm.slice(cut + 1) : norm).toLowerCase();
    return name.replace(/\.exe$/i, "");
}
export function canonicalizeProcessName(file) {
    const base = baseName(file);
    return PROCESS_ALIASES[base] ?? base;
}
export function assertAgentProcess(file, _argv, opts) {
    if (opts?.shell) {
        throw typedError(E.E_PATH, "arbitrary shell is forbidden", "shell");
    }
    const canon = canonicalizeProcessName(file);
    if (!PROCESS_ALLOWLIST.includes(canon)) {
        throw typedError(E.E_POLICY, `process ${canon} is not on the allowlist`, "process");
    }
}
export function assertLoopbackHost(host) {
    const trimmed = host.trim().toLowerCase().replace(/^\[|\]$/g, "");
    if (!LOOPBACK.has(trimmed)) {
        throw typedError(E.E_BIND, "network allowlist is loopback only", "host");
    }
}
export function isShellSpawnForbidden(opts) {
    return opts?.shell === true || opts?.shell === "cmd.exe" || opts?.shell === "powershell.exe";
}
