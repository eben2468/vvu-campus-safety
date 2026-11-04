/** Error codes the app understands (lib/services/api_client.dart). */
export type ApiErrorCode =
  | "invalid-argument"
  | "unauthenticated"
  | "permission-denied"
  | "not-found"
  | "already-exists"
  | "failed-precondition"
  | "internal";

const HTTP_STATUS: Record<ApiErrorCode, number> = {
  "invalid-argument": 400,
  unauthenticated: 401,
  "permission-denied": 403,
  "not-found": 404,
  "already-exists": 409,
  "failed-precondition": 412,
  internal: 500,
};

/** A failure the user should see; [message] is shown in the app as is. */
export class ApiError extends Error {
  constructor(
    readonly code: ApiErrorCode,
    message: string,
  ) {
    super(message);
  }

  get httpStatus(): number {
    return HTTP_STATUS[this.code];
  }
}
