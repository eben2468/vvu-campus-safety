import { cert, getApps, initializeApp, ServiceAccount } from "firebase-admin/app";

import { ApiError } from "./api/errors";

/**
 * The service account from FIREBASE_SERVICE_ACCOUNT. Errors here are worded
 * by hand: JSON.parse's own message can quote part of the private key.
 */
function serviceAccountFrom(json: string): ServiceAccount {
  try {
    return JSON.parse(json) as ServiceAccount;
  } catch {
    throw new ApiError("failed-precondition", "Server setup: FIREBASE_SERVICE_ACCOUNT is not valid JSON.");
  }
}

/**
 * Starts the Firebase Admin SDK once per server instance.
 *
 * On Vercel the service account comes from the FIREBASE_SERVICE_ACCOUNT
 * environment variable (never from the repo). Locally there is no key: the
 * Admin SDK talks to the emulators (see scripts/devServer.ts).
 */
export function initFirebase(): void {
  if (getApps().length > 0) return;
  const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (serviceAccount) {
    initializeApp({ credential: cert(serviceAccountFrom(serviceAccount)) });
  } else {
    initializeApp({ projectId: process.env.GCLOUD_PROJECT ?? "demo-vvu-campus-safety" });
  }
}
