import { ApiError } from "./errors";

/** Who is calling, from their verified Firebase ID token. */
export interface Caller {
  uid: string;
  role?: string;
  verified: boolean;
  email?: string;
}

/** A call from the app: the signed-in caller, if any, and its JSON body. */
export interface ApiRequest {
  caller: Caller | null;
  data: unknown;
}

/** Rejects callers who are not signed in. */
export function requireCaller(request: ApiRequest, message = "Sign in first."): Caller {
  if (!request.caller) throw new ApiError("unauthenticated", message);
  return request.caller;
}

/** Rejects callers who are not signed in as an admin. Returns their uid. */
export function requireAdmin(request: ApiRequest): string {
  const caller = requireCaller(request);
  if (caller.role !== "admin") {
    throw new ApiError("permission-denied", "Only admins can do this.");
  }
  return caller.uid;
}

/** A Firestore document id from the request body, safe to use in a path. */
export function documentId(data: unknown, field: string): string {
  const value = (data as Record<string, unknown> | null)?.[field];
  if (typeof value !== "string" || !/^[\w-]{1,128}$/.test(value)) {
    throw new ApiError("invalid-argument", `Missing or invalid ${field}.`);
  }
  return value;
}
