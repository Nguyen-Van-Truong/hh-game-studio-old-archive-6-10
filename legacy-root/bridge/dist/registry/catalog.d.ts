/**
 * §5.2 required groups and verbs. Tests fail if the live registry misses one.
 * Slash lists in the plan become dotted ids: animation.state-machine → state_machine.
 */
export declare const REQUIRED_VERBS: Readonly<Record<string, readonly string[]>>;
export declare function requiredActionIds(): string[];
export declare const REQUIRED_ACTION_COUNT: number;
