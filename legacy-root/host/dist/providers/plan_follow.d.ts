/**
 * R7-WP6 deciding path: job.plan, then interpret that DAG in order.
 * Genre GDScript is compiled from produceSpec.slug / plan outputs + brief.
 * Not an LLM. First script.write is a complete working engine.
 */
import type { ModelContext, ModelTurn, Provider } from "./types.js";
export declare const PLAN_FOLLOW_MODEL = "job.plan-follow";
interface PlanTask {
    id: string;
    kind: string;
    acceptance: string[];
    outputs: string[];
    commands: string[];
    criterion?: string;
    blocker?: {
        code: string;
        message: string;
    };
}
interface CompiledPlanView {
    status?: string;
    tasks: PlanTask[];
    blockers: Array<{
        code: string;
        message: string;
        task_id?: string;
    }>;
    acceptance: Array<{
        id: string;
        text: string;
    }>;
}
export interface GameColor {
    name: string;
    r: number;
    g: number;
    b: number;
}
export interface GameSpec {
    slug: string;
    scene: string;
    script: string;
    art: string;
    cols: number;
    rows: number;
    pairCount: number;
    winAt: number;
    colors: GameColor[];
    actions: string[];
    tiles: number[];
    acceptance: string[];
}
export interface CompiledAssert {
    name: string;
    key: string;
    op: string;
    value_bool?: boolean;
    value_int?: number;
    value_string?: string;
    node_path?: string;
    inputs: string[];
    criterion: string;
}
export interface AskRow {
    at: number;
    code: string;
    message: string;
    e_gate: boolean;
}
/** Same routing family as brief_compiler / plugin produceSpec. */
export declare function slugFromPlanAndBrief(plan: CompiledPlanView, brief: string): string;
export declare function compileGameSpec(plan: CompiledPlanView, brief: string): GameSpec;
/** Complete working engine from the live job.plan + brief. */
export declare function compilePlanScript(spec: GameSpec): string;
export declare function assertFromAcceptance(text: string, spec: GameSpec): CompiledAssert | undefined;
export declare class PlanFollowProvider implements Provider {
    readonly name = "plan";
    readonly model = "job.plan-follow";
    private readonly brief;
    private readonly asksPath?;
    private walker;
    constructor(brief: string, asksPath?: string);
    generate(ctx: ModelContext): ModelTurn;
}
export declare function loadBriefFile(file: string): string;
export {};
