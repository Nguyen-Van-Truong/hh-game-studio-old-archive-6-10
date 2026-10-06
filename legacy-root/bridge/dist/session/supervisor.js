import { spawn, spawnSync } from "node:child_process";
import { assertAgentProcess } from "../policy/allowlist.js";
import { E, typedError } from "../registry/errors.js";
function forbidShell(opts) {
    if (opts?.shell) {
        throw typedError(E.E_PATH, "process supervisor forbids shell spawn", "shell");
    }
}
/** Argv-array supervisor. Spawn only; shell disabled. */
export class ProcessSupervisor {
    children = new Set();
    spawnAgent(file, argv, opts) {
        assertAgentProcess(file, argv, { shell: opts?.shell === true });
        return this.spawn(file, argv, opts);
    }
    spawn(file, argv, opts) {
        forbidShell(opts);
        assertAgentProcess(file, argv, { shell: false });
        const child = spawn(file, [...argv], {
            ...opts,
            shell: false,
            windowsHide: true,
        });
        this.children.add(child);
        child.once("exit", () => {
            this.children.delete(child);
        });
        return child;
    }
    runSync(file, argv, opts) {
        forbidShell(opts);
        assertAgentProcess(file, argv, { shell: false });
        const result = spawnSync(file, [...argv], {
            ...opts,
            shell: false,
            windowsHide: true,
            encoding: "utf8",
        });
        return {
            status: result.status,
            stdout: result.stdout ?? "",
            stderr: result.stderr ?? "",
        };
    }
    async shutdown(timeoutMs = 2000) {
        const snapshot = [...this.children];
        for (const child of snapshot) {
            if (!child.killed) {
                child.kill();
            }
        }
        const deadline = Date.now() + timeoutMs;
        while (this.children.size > 0 && Date.now() < deadline) {
            await new Promise((r) => setTimeout(r, 25));
        }
        for (const child of [...this.children]) {
            child.kill("SIGKILL");
        }
    }
}
export function pidAlive(pid) {
    if (!Number.isInteger(pid) || pid <= 0) {
        return false;
    }
    try {
        process.kill(pid, 0);
        return true;
    }
    catch {
        return false;
    }
}
