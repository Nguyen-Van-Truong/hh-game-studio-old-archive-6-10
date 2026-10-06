import fs from "node:fs";
import { E, HostError } from "../errors.js";
export const FAKE_MODEL_ID = "fake-deterministic";
/** Inspect then editor state then done. Kill/resume sits between the two tools. */
export const DEFAULT_FAKE_SCRIPT = [
    {
        kind: "tool",
        tool: "godot.project",
        action: "inspect",
        params: { detail: "short" },
    },
    {
        kind: "tool",
        tool: "godot.editor",
        action: "state",
        params: { detail: "short" },
    },
    {
        kind: "done",
        summary: "inspected project and editor state",
    },
];
function asTurn(value, index) {
    if (value === null || typeof value !== "object") {
        throw new HostError(E.E_POLICY, `fake script[${index}] is not an object`, "script");
    }
    const rec = value;
    if (rec.kind === "done") {
        const summary = typeof rec.summary === "string" ? rec.summary : "done";
        return { kind: "done", summary };
    }
    if (rec.kind === "tool" && typeof rec.tool === "string" && typeof rec.action === "string") {
        const params = rec.params !== null && typeof rec.params === "object" && !Array.isArray(rec.params)
            ? rec.params
            : {};
        return { kind: "tool", tool: rec.tool, action: rec.action, params };
    }
    throw new HostError(E.E_POLICY, `fake script[${index}] is not a tool/done turn`, "script");
}
export function loadFakeScript(file) {
    let parsed;
    try {
        parsed = JSON.parse(fs.readFileSync(file, { encoding: "utf8" }));
    }
    catch {
        throw new HostError(E.E_POLICY, "fake script is not JSON", "script");
    }
    if (!Array.isArray(parsed)) {
        throw new HostError(E.E_POLICY, "fake script must be an array", "script");
    }
    return parsed.map((item, i) => asTurn(item, i));
}
export class FakeProvider {
    name = "fake";
    model = FAKE_MODEL_ID;
    script;
    constructor(script = DEFAULT_FAKE_SCRIPT) {
        this.script = script;
    }
    generate(ctx) {
        const turn = this.script[ctx.step];
        if (!turn) {
            return { kind: "done", summary: "script complete" };
        }
        return turn;
    }
}
