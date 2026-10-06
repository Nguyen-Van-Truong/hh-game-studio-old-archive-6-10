import type { Credential } from "../credentials.js";
import type { ModelContext, ModelTurn, Provider } from "./types.js";
/**
 * Pins model/config from the user store. Does not open a network session
 * in this pin — official tests use the fake provider.
 */
export declare class ConfiguredProvider implements Provider {
    readonly name = "configured";
    readonly model: string;
    constructor(cred: Credential);
    generate(_ctx: ModelContext): ModelTurn;
}
