import path from "node:path";
import { resolveCredential } from "./credentials.js";
import { FakeExecutor, McpStdioExecutor } from "./executor.js";
import { E, HostError } from "./errors.js";
import { spawnMcpChild } from "./mcp_child.js";
import { agentHome, isUnderAgentHome, statePath } from "./paths.js";
import { writeJsonAtomic } from "./persist.js";
import { ConfiguredProvider } from "./providers/configured.js";
import { FakeProvider, loadFakeScript } from "./providers/fake.js";
import { loadBriefFile, PlanFollowProvider } from "./providers/plan_follow.js";
import { redactSecrets } from "./redact.js";
import { assertRunnable, compactState, loadHostState, newHostState, pidAlive, saveHostState, } from "./session.js";
import { writeHostSoakResource } from "./soak_resource.js";
import { newUlid, parseUlid } from "./ulid.js";
/**
 * Host is the ONLY class that calls the model and decides the tool loop.
 * Sidecar/plugin stay deterministic execution. Interactive IDE clients are
 * this same class; unattended uses a persistent process of this class.
 */
export class Host {
    provider;
    executor;
    secrets;
    state;
    holdAfterDecision;
    holdUntilDeadline;
    fast;
    briefText;
    mcp;
    usesMcp;
    held = false;
    constructor(provider, executor, state, holdAfterDecision, secrets, extra) {
        this.provider = provider;
        this.executor = executor;
        this.state = state;
        this.holdAfterDecision = holdAfterDecision;
        this.secrets = secrets;
        this.holdUntilDeadline = extra?.holdUntilDeadline === true;
        this.fast = extra?.fast === true;
        this.briefText = extra?.briefText ?? "";
        this.usesMcp = extra?.usesMcp === true;
        if (extra?.mcp) {
            this.mcp = extra.mcp;
        }
    }
    static create(opts) {
        const sessionId = opts.sessionId ? parseUlid(opts.sessionId, "session_id") : newUlid();
        const taskId = opts.taskId ? parseUlid(opts.taskId, "task_id") : newUlid();
        const commandId = opts.commandId ? parseUlid(opts.commandId, "command_id") : newUlid();
        const persist = statePath(sessionId);
        const built = buildProvider({ ...opts, sessionId });
        if (!isUnderAgentHome(persist)) {
            throw new HostError(E.E_PATH, "host state escaped HHGodotAgent", "persist");
        }
        const state = newHostState({
            session_id: sessionId,
            task_id: taskId,
            command_id: commandId,
            mode: opts.mode,
            provider: built.provider.name,
            model: built.provider.model,
            max_steps: opts.maxSteps ?? (opts.providerName === "plan" ? 400 : 16),
            persist_path: persist,
        });
        const wired = wireExecutor(opts, persist);
        const host = new Host(built.provider, wired.executor, state, opts.holdAfterDecision === true, built.secrets, {
            holdUntilDeadline: opts.holdUntilDeadline === true,
            fast: opts.fast === true || process.env.HH_ZERO_TOUCH_FAST === "1",
            ...(built.briefText ? { briefText: built.briefText } : {}),
            ...(wired.mcp ? { mcp: wired.mcp } : {}),
            usesMcp: wired.kind === "mcp-stdio",
        });
        if (wired.kind === "fake") {
            host.stampHostExecutor("fake");
        }
        host.stampContext("plan=host task");
        host.persist();
        return host;
    }
    static resume(opts) {
        const sessionId = parseUlid(opts.sessionId, "session_id");
        const state = loadHostState(sessionId);
        if (pidAlive(state.writer_pid) && state.writer_pid !== process.pid) {
            throw new HostError(E.E_BUSY, "session has a live host process", "writer_pid");
        }
        const resumeOpts = {
            mode: opts.mode,
            providerName: opts.providerName === "plan" || state.provider === "plan"
                ? "plan"
                : state.provider === "configured"
                    ? "configured"
                    : "fake",
        };
        if (opts.scriptPath) {
            resumeOpts.scriptPath = opts.scriptPath;
        }
        if (opts.briefPath) {
            resumeOpts.briefPath = opts.briefPath;
        }
        if (opts.mcpProject) {
            resumeOpts.mcpProject = opts.mcpProject;
        }
        if (opts.secrets) {
            resumeOpts.secrets = opts.secrets;
        }
        const built = buildProvider(resumeOpts);
        const now = Date.now();
        state.wakeup_at = now;
        state.handoff = { from_pid: state.writer_pid, to_pid: process.pid, at: now };
        state.writer_pid = process.pid;
        state.heartbeat_at = now;
        if (state.phase === "held_after_decision") {
            state.phase = "running";
        }
        const wired = wireExecutor(opts, state.persist_path);
        const host = new Host(built.provider, wired.executor, state, false, built.secrets, {
            holdUntilDeadline: opts.holdUntilDeadline === true,
            fast: opts.fast === true || process.env.HH_ZERO_TOUCH_FAST === "1",
            ...(built.briefText ? { briefText: built.briefText } : {}),
            ...(wired.mcp ? { mcp: wired.mcp } : {}),
            usesMcp: wired.kind === "mcp-stdio",
        });
        if (wired.kind === "fake") {
            host.stampHostExecutor("fake");
        }
        host.stampContext(state.plan.summary ? `plan=${state.plan.summary}` : "plan=host task");
        host.persist();
        return host;
    }
    static load(sessionId) {
        return loadHostState(parseUlid(sessionId, "session_id"));
    }
    static compact(sessionId, opts) {
        const state = compactState(loadHostState(parseUlid(sessionId, "session_id")));
        saveHostState(state);
        const projectRoot = opts?.projectRoot;
        const jobId = opts?.jobId;
        if (projectRoot && jobId) {
            writeHostSoakResource({ projectRoot, jobId, state });
        }
        return state;
    }
    static cancel(sessionId) {
        const state = loadHostState(parseUlid(sessionId, "session_id"));
        state.cancelled = true;
        state.phase = "cancelled";
        state.heartbeat_at = Date.now();
        saveHostState(state);
        return state;
    }
    modelContext() {
        const ctx = {
            task_id: this.state.task_id,
            command_id: this.state.command_id,
            plan_summary: this.state.plan.summary,
            step: this.state.tools.length,
            last_tools: this.state.tools.map((row) => ({ tool: row.tool, action: row.action })),
            last_results: this.state.tools.map((row) => ({
                ok: row.result.ok,
                after: row.result.after ?? {},
                ...(row.result.ok ? {} : { error: row.result.error }),
            })),
            deadline_at: this.state.deadline_at,
            now: Date.now(),
        };
        if (this.briefText) {
            ctx.brief = this.briefText;
        }
        return ctx;
    }
    log(line) {
        process.stderr.write(`${redactSecrets(line, this.secrets)}\n`);
    }
    persist() {
        this.state.persist_path = statePath(this.state.session_id);
        if (!isUnderAgentHome(this.state.persist_path, agentHome())) {
            throw new HostError(E.E_PATH, "host state escaped HHGodotAgent", "persist");
        }
        saveHostState(this.state);
    }
    /** Persist HOST only after plugin connect or a live FakeExecutor create. */
    stampHostExecutor(kind) {
        this.state.executor = kind;
    }
    stampContext(extra) {
        const exec = this.state.executor === "mcp-stdio" || this.state.executor === "fake"
            ? ` executor=${this.state.executor}`
            : "";
        this.state.context_summary =
            `task=${this.state.task_id} command=${this.state.command_id} ${extra}${exec}`;
    }
    treeHasNodeList(value) {
        if (Array.isArray(value)) {
            return value.length > 0;
        }
        if (value === null || typeof value !== "object") {
            return false;
        }
        const rec = value;
        return ((Array.isArray(rec.items) && rec.items.length > 0) ||
            (Array.isArray(rec.nodes) && rec.nodes.length > 0));
    }
    /** scene.read success needs a tree with items or a node list, not path + empty dict. */
    observeHasPayload(after) {
        if (after === null || typeof after !== "object" || Array.isArray(after)) {
            return false;
        }
        const rec = after;
        if (this.treeHasNodeList(rec.tree) || this.treeHasNodeList(rec.nodes) || this.treeHasNodeList(rec.items)) {
            return true;
        }
        return false;
    }
    noteSuccessfulObserve(after) {
        if (!this.observeHasPayload(after)) {
            return;
        }
        const now = Date.now();
        this.state.last_observe_ok_at = now;
        this.state.heartbeat_at = now;
        this.persist();
    }
    async finishInflight() {
        const inflight = this.state.inflight;
        if (!inflight) {
            return;
        }
        const result = await Promise.resolve(this.executor.execute({
            tool: inflight.tool,
            action: inflight.action,
            params: inflight.params,
        }));
        const record = {
            task_id: inflight.task_id,
            command_id: inflight.command_id,
            tool: inflight.tool,
            action: inflight.action,
            result,
            params: inflight.params,
        };
        this.state.tools.push(record);
        delete this.state.inflight;
        this.state.phase = "awaiting_model";
        if (result.ok && this.usesMcp) {
            this.stampHostExecutor("mcp-stdio");
        }
        this.stampContext(`last=${inflight.tool}.${inflight.action}`);
        this.persist();
        this.log(`host tool ${inflight.tool}.${inflight.action} session=${this.state.session_id}`);
    }
    hangForKill() {
        this.log(`host holding after decision session=${this.state.session_id}`);
        const beat = () => {
            this.state.heartbeat_at = Date.now();
            saveHostState(this.state);
            this.writeReportFile(this.report(false));
        };
        setInterval(beat, 1000);
    }
    /**
     * Decide the next tool via the provider, persist in-flight command_id,
     * optionally hold so a test can kill this process, then execute.
     */
    async run() {
        try {
            if (this.usesMcp) {
                await this.waitForPlugin();
            }
            if (this.state.inflight) {
                await this.finishInflight();
            }
            while (this.state.phase !== "done" && this.state.phase !== "cancelled") {
                assertRunnable(this.state);
                const turn = this.provider.generate(this.modelContext());
                this.state.budget.used_steps += 1;
                if (turn.kind === "done") {
                    this.state.plan = { summary: turn.summary };
                    // Keep the dedicated executor field. done must not clear it.
                    this.stampContext(`plan=${turn.summary}`);
                    this.persist();
                    if (this.holdUntilDeadline && !this.fast) {
                        // Does not return until consecutive MCP observe failures or cancel.
                        // DURATION90 requires host still live at 5400s with successful scene.read.
                        await this.observeUntilDeadline();
                    }
                    this.state.phase = "done";
                    this.persist();
                    break;
                }
                this.state.inflight = {
                    tool: turn.tool,
                    action: turn.action,
                    params: turn.params,
                    command_id: this.state.command_id,
                    task_id: this.state.task_id,
                };
                this.state.phase = "held_after_decision";
                this.persist();
                if (this.holdAfterDecision && !this.held) {
                    this.held = true;
                    this.hangForKill();
                    const held = this.report(false);
                    this.writeReportFile(held);
                    return held;
                }
                await this.finishInflight();
            }
            const done = this.report(true);
            this.writeReportFile(done);
            return done;
        }
        catch (err) {
            if (err instanceof HostError) {
                this.state.phase = err.code === E.E_CANCELLED ? "cancelled" : "failed";
                this.persist();
                const report = this.report(false);
                report.error = err.typed();
                this.writeReportFile(report);
                return report;
            }
            throw err;
        }
    }
    async waitForPlugin() {
        const deadline = Date.now() + 180_000;
        while (Date.now() < deadline) {
            const result = await Promise.resolve(this.executor.execute({ tool: "hh.plugin_noop", action: "noop", params: {} }));
            if (result.ok) {
                this.stampHostExecutor("mcp-stdio");
                this.stampContext(this.state.plan.summary ? `plan=${this.state.plan.summary}` : "plan=host task");
                this.persist();
                this.log(`host plugin connected session=${this.state.session_id}`);
                return;
            }
            await new Promise((resolve) => {
                setTimeout(resolve, 1000);
            });
        }
        throw new HostError(E.E_TIMEOUT, "plugin did not connect to MCP sidecar", "plugin");
    }
    async observeUntilDeadline() {
        let scene = "res://scenes/memory/board.tscn";
        for (const row of this.state.tools) {
            if (row.action === "plan" && row.result.ok) {
                const plan = row.result.after.plan;
                if (plan && typeof plan === "object" && !Array.isArray(plan)) {
                    const tasks = plan.tasks;
                    if (Array.isArray(tasks)) {
                        for (const task of tasks) {
                            if (task &&
                                typeof task === "object" &&
                                task.id === "produce_scene") {
                                const outputs = task.outputs;
                                if (Array.isArray(outputs) && typeof outputs[0] === "string") {
                                    scene = outputs[0];
                                }
                            }
                        }
                    }
                }
            }
        }
        this.state.phase = "observing";
        this.persist();
        // Periodic report.json so a 5400s TerminateProcess still has HOST proof.
        this.writeReportFile(this.report(false));
        this.log(`host observe hold session=${this.state.session_id}`);
        // Pump until the harness kills this process after 5400s. Do not exit at
        // deadline_at: DURATION90 requires host still live at 5400s. McpStdioExecutor
        // returns {ok:false} and does not throw — check result.ok. Consecutive
        // failed scene.read / timeline ticks fail the hold (PID husk is not LIVE).
        let failedTicks = 0;
        const maxFailedTicks = 3;
        for (;;) {
            if (this.state.cancelled) {
                throw new HostError(E.E_CANCELLED, "host session cancelled", "cancel");
            }
            const result = await Promise.resolve(this.executor.execute({
                tool: "godot.scene",
                action: "read",
                params: { path: scene, detail: "short" },
            }));
            const timeline = await Promise.resolve(this.executor.execute({
                tool: "godot.observer",
                action: "timeline",
                params: { detail: "short" },
            }));
            const after = result.ok === true ? result.after : {};
            const payloadOk = this.observeHasPayload(after);
            if (result.ok !== true || !payloadOk || timeline.ok !== true) {
                failedTicks += 1;
                const which = result.ok !== true || !payloadOk ? "scene.read" : "observer.timeline";
                this.log(`host observe ok=false session=${this.state.session_id} which=${which} n=${failedTicks}`);
                if (failedTicks >= maxFailedTicks) {
                    throw new HostError(E.E_UNVERIFIED, "consecutive observe scene.read not ok", "observe");
                }
            }
            else {
                failedTicks = 0;
                this.noteSuccessfulObserve(after);
                this.log(`host observe tick session=${this.state.session_id} ok=1`);
            }
            this.writeReportFile(this.report(false));
            await new Promise((resolve) => {
                setTimeout(resolve, 30_000);
            });
        }
    }
    close() {
        this.mcp?.dispose();
    }
    writeReportFile(report) {
        const dest = path.join(path.dirname(this.state.persist_path), "report.json");
        writeJsonAtomic(dest, report);
    }
    report(ok = this.state.phase === "done") {
        const out = {
            ok,
            mode: this.state.mode,
            provider: this.state.provider,
            model: this.state.model,
            session_id: this.state.session_id,
            task_id: this.state.task_id,
            command_id: this.state.command_id,
            started_at: this.state.started_at,
            deadline_at: this.state.deadline_at,
            session_ms: this.state.session_ms,
            phase: this.state.phase,
            compacted: this.state.compacted,
            persist_path: this.state.persist_path,
            tools: this.state.tools.map((row) => ({
                task_id: row.task_id,
                command_id: row.command_id,
                tool: row.tool,
                action: row.action,
                result: row.result,
                ...(row.params ? { params: row.params } : {}),
            })),
            plan: this.state.plan,
            context_summary: this.state.context_summary,
            executor: this.state.executor === "mcp-stdio" ? "mcp-stdio" : "fake",
        };
        return out;
    }
}
function wireExecutor(opts, persistPath) {
    if (!opts.mcpProject) {
        return { executor: new FakeExecutor(), kind: "fake" };
    }
    const mcp = spawnMcpChild({
        projectRoot: opts.mcpProject,
        logDir: path.dirname(persistPath),
    });
    return { executor: new McpStdioExecutor(mcp), kind: "mcp-stdio", mcp };
}
function buildProvider(opts) {
    const secrets = [...(opts.secrets ?? [])];
    if (opts.providerName === "configured") {
        const cred = resolveCredential("configured");
        secrets.push(cred.token);
        return { provider: new ConfiguredProvider(cred), secrets };
    }
    if (opts.providerName === "plan") {
        const briefText = opts.briefPath ? loadBriefFile(opts.briefPath) : "";
        const asksPath = opts.sessionId
            ? path.join(path.dirname(statePath(opts.sessionId)), "asks.jsonl")
            : undefined;
        return { provider: new PlanFollowProvider(briefText, asksPath), secrets, briefText };
    }
    const script = opts.scriptPath ? loadFakeScript(opts.scriptPath) : undefined;
    return { provider: new FakeProvider(script), secrets };
}
export function showSession(sessionId) {
    const state = Host.load(sessionId);
    return {
        ok: true,
        session_id: state.session_id,
        task_id: state.task_id,
        command_id: state.command_id,
        phase: state.phase,
        compacted: state.compacted,
        plan: state.plan,
        context_summary: state.context_summary,
        executor: state.executor === "mcp-stdio" ? "mcp-stdio" : "fake",
        persist_path: state.persist_path,
        started_at: state.started_at,
        deadline_at: state.deadline_at,
        session_ms: state.session_ms,
        last_observe_ok_at: state.last_observe_ok_at ?? 0,
        tools: state.tools.map((row) => ({
            task_id: row.task_id,
            command_id: row.command_id,
            tool: row.tool,
            action: row.action,
        })),
    };
}
