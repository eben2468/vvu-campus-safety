import { cert, getApps, initializeApp } from "firebase-admin/app";

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
    initializeApp({ credential: cert(JSON.parse(serviceAccount)) });
  } else {
    initializeApp({ projectId: process.env.GCLOUD_PROJECT ?? "demo-vvu-campus-safety" });
  }
}
