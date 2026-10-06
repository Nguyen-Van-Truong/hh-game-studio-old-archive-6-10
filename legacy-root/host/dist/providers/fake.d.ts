import type { ModelContext, ModelTurn, Provider } from "./types.js";
export declare const FAKE_MODEL_ID = "fake-deterministic";
/** Inspect then editor state then done. Kill/resume sits between the two tools. */
export declare const DEFAULT_FAKE_SCRIPT: readonly ModelTurn[];
export declare function loadFakeScript(file: string): ModelTurn[];
export declare class FakeProvider implements Provider {
    readonly name = "fake";
    readonly model = "fake-deterministic";
    private readonly script;
    constructor(script?: readonly ModelTurn[]);
    generate(ctx: ModelContext): ModelTurn;
}
