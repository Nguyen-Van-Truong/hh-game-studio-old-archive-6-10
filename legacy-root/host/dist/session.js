import { E, HostError } from "./errors.js";
import { SESSION_MS, statePath } from "./paths.js";
import { readJsonFile, writeJsonAtomic } from "./persist.js";
import { stripSecrets } from "./redact.js";
export function newHostState(input) {
    const now = input.now ?? Date.now();
    return {
        session_id: input.session_id,
        task_id: input.task_id,
        command_id: input.command_id,
        started_at: now,
        deadline_at: now + SESSION_MS,
        heartbeat_at: now,
        session_ms: SESSION_MS,
        phase: "running",
        mode: input.mode,
        provider: input.provider,
        model: input.model,
        budget: { max_steps: input.max_steps, used_steps: 0 },
        cancelled: false,
        compacted: false,
        plan: { summary: "host task" },
        context_summary: `task=${input.task_id} command=${input.command_id} plan=host task`,
        tools: [],
        transcript: [],
        writer_pid: process.pid,
        persist_path: input.persist_path,
    };
}
function asRecord(value) {
    if (value !== null && typeof value === "object" && !Array.isArray(value)) {
        return value;
    }
    throw new HostError(E.E_POLICY, "host state is not an object", "session");
}
function requireString(rec, key) {
    const v = rec[key];
    if (typeof v !== "string" || v === "") {
        throw new HostError(E.E_POLICY, `host state missing ${key}`, key);
    }
    return v;
}
function requireNumber(rec, key) {
    const v = rec[key];
    if (typeof v !== "number" || !Number.isFinite(v)) {
        throw new HostError(E.E_POLICY, `host state missing ${key}`, key);
    }
    return v;
}
export function parseHostState(value) {
    const rec = asRecord(stripSecrets(value));
    const budgetRec = asRecord(rec.budget ?? {});
    const planRec = asRecord(rec.plan ?? { summary: "host task" });
    const toolsRaw = Array.isArray(rec.tools) ? rec.tools : [];
    const tools = [];
    for (const row of toolsRaw) {
        const item = asRecord(row);
        const result = item.result;
        if (result === null || typeof result !== "object") {
            throw new HostError(E.E_POLICY, "tool record missing result", "tools");
        }
        const params = item.params !== null && typeof item.params === "object" && !Array.isArray(item.params)
            ? item.params
            : undefined;
        tools.push({
            task_id: requireString(item, "task_id"),
            command_id: requireString(item, "command_id"),
            tool: requireString(item, "tool"),
            action: requireString(item, "action"),
            result: result,
            ...(params ? { params } : {}),
        });
    }
    const state = {
        session_id: requireString(rec, "session_id"),
        task_id: requireString(rec, "task_id"),
        command_id: requireString(rec, "command_id"),
        started_at: requireNumber(rec, "started_at"),
        deadline_at: requireNumber(rec, "deadline_at"),
        heartbeat_at: requireNumber(rec, "heartbeat_at"),
        session_ms: requireNumber(rec, "session_ms"),
        phase: requireString(rec, "phase"),
        mode: requireString(rec, "mode"),
        provider: requireString(rec, "provider"),
        model: requireString(rec, "model"),
        budget: {
            max_steps: requireNumber(budgetRec, "max_steps"),
            used_steps: requireNumber(budgetRec, "used_steps"),
        },
        cancelled: rec.cancelled === true,
        compacted: rec.compacted === true,
        plan: { summary: typeof planRec.summary === "string" ? planRec.summary : "host task" },
        context_summary: typeof rec.context_summary === "string" ? rec.context_summary : "",
        tools,
        transcript: Array.isArray(rec.transcript) ? rec.transcript : [],
        writer_pid: typeof rec.writer_pid === "number" ? rec.writer_pid : 0,
        persist_path: requireString(rec, "persist_path"),
    };
    if (rec.executor === "mcp-stdio" || rec.executor === "fake") {
        state.executor = rec.executor;
    }
    if (rec.inflight !== null && typeof rec.inflight === "object") {
        const inf = asRecord(rec.inflight);
        state.inflight = {
            tool: requireString(inf, "tool"),
            action: requireString(inf, "action"),
            params: inf.params !== null && typeof inf.params === "object" && !Array.isArray(inf.params)
                ? inf.params
                : {},
            command_id: requireString(inf, "command_id"),
            task_id: requireString(inf, "task_id"),
        };
    }
    if (typeof rec.last_observe_ok_at === "number" && Number.isFinite(rec.last_observe_ok_at)) {
        state.last_observe_ok_at = rec.last_observe_ok_at;
    }
    if (typeof rec.wakeup_at === "number") {
        state.wakeup_at = rec.wakeup_at;
    }
    if (rec.handoff !== null && typeof rec.handoff === "object") {
        const h = asRecord(rec.handoff);
        state.handoff = {
            from_pid: requireNumber(h, "from_pid"),
            to_pid: requireNumber(h, "to_pid"),
            at: requireNumber(h, "at"),
        };
    }
    return state;
}
export function saveHostState(state) {
    writeJsonAtomic(state.persist_path, state);
}
export function loadHostState(sessionId) {
    const file = statePath(sessionId);
    const state = parseHostState(readJsonFile(file));
    if (state.session_id !== sessionId) {
        throw new HostError(E.E_POLICY, "session_id mismatch on disk", "session_id");
    }
    return state;
}
export function compactState(state) {
    const next = {
        ...state,
        compacted: true,
        transcript: [],
        context_summary: `task=${state.task_id} command=${state.command_id} plan=${state.plan.summary}`,
        heartbeat_at: Date.now(),
    };
    // Copy the dedicated field only. Do not invent mcp-stdio from a substring.
    // Do not drop live mcp-stdio because plan.summary contains executor=fake.
    if (state.executor === "mcp-stdio" || state.executor === "fake") {
        next.executor = state.executor;
        next.context_summary = `${next.context_summary} executor=${state.executor}`;
    }
    return next;
}
export function assertRunnable(state, now = Date.now()) {
    if (state.cancelled) {
        throw new HostError(E.E_CANCELLED, "host session cancelled", "cancel");
    }
    if (state.phase !== "observing" && now > state.deadline_at) {
        throw new HostError(E.E_TIMEOUT, "90-minute host session expired", "deadline");
    }
    if (state.budget.used_steps >= state.budget.max_steps) {
        throw new HostError(E.E_POLICY, "host budget exhausted", "budget");
    }
}
export function pidAlive(pid) {
    if (pid <= 0) {
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
