import { E, typedError } from "../registry/errors.js";
import { isFaultHook } from "./states.js";
export const LEDGER_FAULT_EXIT = 99;
export const LEDGER_ATTEMPT_CRASH_EXIT = 98;
export class LedgerPluginDeath extends Error {
    hook;
    constructor(hook) {
        super(`ledger plugin death at ${hook}`);
        this.name = "LedgerPluginDeath";
        this.hook = hook;
    }
}
function env(name) {
    return (process.env[name] ?? "").trim();
}
/** Kill sidecar, or throw so the caller can drop the plugin, after a flushed state. */
export function maybeFault(hook, commandId) {
    const at = env("HH_LEDGER_FAULT_AT");
    if (!isFaultHook(at) || at !== hook) {
        return;
    }
    const only = env("HH_LEDGER_FAULT_COMMAND_ID");
    if (only && only !== commandId) {
        return;
    }
    const mode = env("HH_LEDGER_FAULT_MODE") || "sidecar";
    if (mode === "plugin") {
        throw new LedgerPluginDeath(hook);
    }
    process.stderr.write(`hh-ledger-fault=${hook}\n`);
    process.exit(LEDGER_FAULT_EXIT);
}
export function maybeCrashAfterDispatchAttempt(commandId) {
    if (env("HH_LEDGER_CRASH_AFTER_DISPATCH_ATTEMPT") !== "1") {
        return;
    }
    const only = env("HH_LEDGER_FAULT_COMMAND_ID");
    if (only && only !== commandId) {
        return;
    }
    process.stderr.write("hh-ledger-fault=dispatch_attempted\n");
    process.exit(LEDGER_ATTEMPT_CRASH_EXIT);
}
export function faultEnvError(hook) {
    return typedError(E.E_UNCERTAIN, `interrupted at ${hook}`, "");
}
