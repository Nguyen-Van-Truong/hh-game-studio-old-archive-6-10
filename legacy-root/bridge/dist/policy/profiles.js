/** Profile / side-effect gates. OWNER_AUTOPILOT is project-scoped, not unrestricted OS. */
import { E, typedError } from "../registry/errors.js";
import { POLICIES } from "../registry/types.js";
export const DEFAULT_POLICY = "OWNER_AUTOPILOT";
export function normalizePolicy(raw) {
    if (raw === "OBSERVE" || raw === "EDIT" || raw === "OWNER_AUTOPILOT") {
        return raw;
    }
    return DEFAULT_POLICY;
}
export function isPolicy(value) {
    return POLICIES.includes(value);
}
export function isMutatingSideEffect(side) {
    return side === "mutate" || side === "destructive" || side === "external";
}
export function profileAllows(policy, side, approvedDestructive) {
    if (side === "read" || side === "view" || side === "") {
        return true;
    }
    if (policy === "OBSERVE") {
        return false;
    }
    if (policy === "EDIT") {
        if (side === "mutate") {
            return true;
        }
        if (side === "destructive") {
            return approvedDestructive;
        }
        return false;
    }
    return side === "mutate" || side === "destructive" || side === "external";
}
export function denyProfile(policy, side, approvedDestructive) {
    if (profileAllows(policy, side, approvedDestructive)) {
        return undefined;
    }
    if (policy === "OBSERVE") {
        return typedError(E.E_POLICY, "OBSERVE allows read/view/noop only", "policy");
    }
    if (policy === "EDIT" && side === "destructive" && !approvedDestructive) {
        return typedError(E.E_POLICY, "EDIT requires approve before destructive", "policy");
    }
    return typedError(E.E_POLICY, `${policy} does not allow ${side}`, "policy");
}
