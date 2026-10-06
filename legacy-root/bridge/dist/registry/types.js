/** Shared types for the action registry (R2-WP1). No live editor dispatch. */
export const PROTOCOL = "hh-godot-agent/1";
export const REGISTRY_VERSION = "hh-godot-actions/1";
export const VARIANT_SCHEMA_VERSION = "hh-godot-variant/1";
export const ACTION_VERSION = "1";
export const SIDE_EFFECTS = [
    "read",
    "view",
    "mutate",
    "destructive",
    "external",
];
export const UNDO_STRATEGIES = [
    "none",
    "n/a",
    "editor_undo_redo",
    "atomic_file",
    "project_settings_save",
    "git_checkpoint",
    "job_supervisor",
];
export const DESCRIBE_KINDS = [
    "version",
    "class",
    "property",
    "method",
    "action",
];
export const POLICIES = ["OBSERVE", "EDIT", "OWNER_AUTOPILOT"];
export const RESULT_SCHEMA = {
    type: "object",
    additionalProperties: false,
    required: ["ok", "command_id", "postcondition"],
    properties: {
        ok: { type: "boolean" },
        command_id: { type: "string", minLength: 26, maxLength: 26 },
        changed: { type: "boolean" },
        before: { type: "object", additionalProperties: true },
        after: { type: "object", additionalProperties: true },
        postcondition: {
            type: "object",
            additionalProperties: false,
            required: ["verified", "checks"],
            properties: {
                verified: { type: "boolean" },
                checks: { type: "array", items: { type: "string" } },
            },
        },
        undo_action: { type: "string" },
        evidence: { type: "array", items: { type: "string" } },
        warnings: { type: "array", items: { type: "string" } },
        error: {
            type: "object",
            additionalProperties: false,
            properties: {
                code: { type: "string" },
                message: { type: "string" },
                path: { type: "string" },
            },
        },
    },
};
export const FORBIDDEN_CLIENT_FIELDS = [
    "session_id",
    "actor",
    "actor_id",
    "project_id",
    "policy",
    "profile",
    "capability",
    "capability_grant",
    "grants",
];
export const ENVELOPE_ALLOWED_FIELDS = [
    "protocol",
    "command_id",
    "method",
    "action",
    "params",
    "precondition",
    "presentation",
    "action_version",
];
