import type { ProcessSupervisor } from "./supervisor.js";
/** Current-user ACL on Windows via icacls argv. chmod 0700 elsewhere. Fail closed. */
export declare function applyCurrentUserAcl(target: string, supervisor: ProcessSupervisor): void;
