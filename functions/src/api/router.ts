import { getAuth } from "firebase-admin/auth";

import { adminCreateUser, adminImportRoster, adminSetRole, adminUpdateSettings } from "../admin";
import { runBackup } from "../backup";
import { notifyAnnouncement, notifyMessage } from "../chat";
import { initFirebase } from "../firebase";
import { sweepIncidents, syncIncidentRoute } from "../incidents";
import { uploadPhoto } from "../photos";
import { hasBlobStore } from "../photoStore";
import { verifyId } from "../verifyId";
import { ApiError } from "./errors";
import { ApiRequest, Caller } from "./request";

type Route = (request: ApiRequest) => Promise<unknown>;

/** Calls from the app, each checking its own caller. */
const appRoutes: Record<string, Route> = {
  verifyId,
  adminCreateUser,
  adminSetRole,
  adminImportRoster,
  adminUpdateSettings,
  syncIncident: syncIncidentRoute,
  notifyMessage,
  notifyAnnouncement,
  uploadPhoto,
};

/** Scheduled jobs: only callers holding CRON_SECRET may run these. */
const cronRoutes: Record<string, () => Promise<unknown>> = {
  sweep: sweepIncidents,
  backup: runBackup,
};

export interface HttpInput {
  method: string;
  /** The last part of the URL, e.g. `verifyId`. */
  route: string;
  authorization?: string;
  body: unknown;
}

export interface HttpOutput {
  status: number;
  headers: Record<string, string>;
  body: unknown;
}

/**
 * The app authenticates with a bearer token, not cookies, so any origin
 * may call the API: the dashboard's address and localhost alike.
 */
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Authorization, Content-Type",
};

function bearerToken(authorization?: string): string | null {
  const match = /^Bearer (.+)$/.exec(authorization ?? "");
  return match ? match[1] : null;
}

async function callerFrom(authorization?: string): Promise<Caller | null> {
  const token = bearerToken(authorization);
  if (!token) return null;
  try {
    const decoded = await getAuth().verifyIdToken(token);
    return {
      uid: decoded.uid,
      role: typeof decoded.role === "string" ? decoded.role : undefined,
      verified: decoded.verified === true,
      email: decoded.email,
    };
  } catch (error) {
    const code = (error as { code?: string }).code ?? "unknown";
    if (code === "auth/id-token-expired") {
      throw new ApiError("unauthenticated", "Your session has expired. Sign in again.");
    }
    console.error("Could not verify an ID token", code, error);
    throw new ApiError("unauthenticated", `The server could not verify your sign-in (${code}).`);
  }
}

function projectIdIn(serviceAccount: string): string {
  try {
    return (JSON.parse(serviceAccount) as { project_id?: string }).project_id ?? "(no project_id)";
  } catch {
    return "(not valid JSON)";
  }
}

/** Which Firebase project and stores the server is set up for. No secrets. */
function health() {
  const key = process.env.FIREBASE_SERVICE_ACCOUNT;
  return {
    vercelEnvironment: process.env.VERCEL_ENV ?? null,
    vercelUrl: process.env.VERCEL_PROJECT_PRODUCTION_URL ?? null,
    serviceAccountSet: Boolean(key),
    projectId: key ? projectIdIn(key) : null,
    blobConnected: hasBlobStore(),
    cronSecretSet: Boolean(process.env.CRON_SECRET),
    backupKeySet: Boolean(process.env.BACKUP_KEY),
  };
}

async function dispatch(input: HttpInput): Promise<unknown> {
  if (input.route === "health") return health();
  const cron = cronRoutes[input.route];
  if (cron) {
    const secret = process.env.CRON_SECRET;
    if (!secret || bearerToken(input.authorization) !== secret) {
      throw new ApiError("permission-denied", "Not allowed.");
    }
    return cron();
  }
  const route = appRoutes[input.route];
  if (!route || input.method !== "POST") {
    throw new ApiError("not-found", "Unknown request.");
  }
  return route({ caller: await callerFrom(input.authorization), data: input.body });
}

/** Runs one API call. Shared by Vercel (api/index.ts) and the dev server. */
export async function handleApi(input: HttpInput): Promise<HttpOutput> {
  if (input.method === "OPTIONS") return { status: 204, headers: CORS_HEADERS, body: null };
  try {
    initFirebase();
    return { status: 200, headers: CORS_HEADERS, body: { result: (await dispatch(input)) ?? null } };
  } catch (error) {
    if (error instanceof ApiError) {
      return {
        status: error.httpStatus,
        headers: CORS_HEADERS,
        body: { error: { code: error.code, message: error.message } },
      };
    }
    console.error("API error", input.route, error);
    return {
      status: 500,
      headers: CORS_HEADERS,
      body: { error: { code: "internal", message: "Something went wrong. Please try again." } },
    };
  }
}
