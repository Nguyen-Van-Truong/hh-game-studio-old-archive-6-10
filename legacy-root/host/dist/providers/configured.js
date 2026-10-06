import { E, HostError } from "../errors.js";
/**
 * Pins model/config from the user store. Does not open a network session
 * in this pin — official tests use the fake provider.
 */
export class ConfiguredProvider {
    name = "configured";
    model;
    constructor(cred) {
        this.model = cred.model;
    }
    generate(_ctx) {
        throw new HostError(E.E_EXTERNAL, "configured provider does not open a network session in this pin", "network");
    }
}
