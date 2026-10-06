import { PROTOCOL } from "../registry/types.js";
export interface HelloRequest {
    type: "hello";
    protocol: string;
    project_id: string;
    token: string;
}
export interface HelloOk {
    ok: true;
    type: "hello_ok";
    protocol: typeof PROTOCOL;
    project_id: string;
    session_id: string;
}
export interface HelloErr {
    ok: false;
    type: "hello_err";
    error: {
        code: string;
        message: string;
        path: string;
    };
}
export declare function parseHello(raw: unknown): HelloRequest | HelloErr;
export declare function evaluateHello(hello: HelloRequest, expected: {
    protocol: string;
    projectId: string;
    token: string;
    sessionId: string;
}): HelloOk | HelloErr;
