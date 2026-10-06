/** Job-scoped file/scene/resource leases under r7w4/<job>/locks (not .hh-agent). */
import { LeaseTable } from "../policy/leases.js";
export declare function jobLeaseTable(projectRoot: string, jobId: string): LeaseTable;
