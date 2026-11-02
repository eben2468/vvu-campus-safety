import { getAuth } from "firebase-admin/auth";
import { FieldValue, GeoPoint, getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";

import {
  AuditEntry,
  chunk,
  parseCreateUserInput,
  parseRosterRows,
  parseSetRoleInput,
  setRoleAuditEntries,
} from "./adminLogic";
import { changedSettings, LatLng, parseSettingsInput } from "./settingsLogic";

/**
 * Admin-only callables used by the web dashboard (docs/ARCHITECTURE.md §5).
 * Each one checks the caller's `role` claim, makes the change with the
 * Admin SDK and writes an `auditLogs` entry.
 */

/** Rejects callers who are not signed in as an admin. Returns their uid. */
function requireAdmin(request: CallableRequest): string {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  if (request.auth.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can do this.");
  }
  return request.auth.uid;
}

function audit(entry: AuditEntry) {
  return { ...entry, timestamp: FieldValue.serverTimestamp() };
}

/** Creates an officer or admin account with a temporary password. */
export const adminCreateUser = onCall(async (request) => {
  const actorId = requireAdmin(request);
  const parsed = parseCreateUserInput(request.data);
  if (!parsed.ok) throw new HttpsError("invalid-argument", parsed.message);
  const input = parsed.value;

  const auth = getAuth();
  const user = await auth
    .createUser({
      email: input.email,
      password: input.password,
      displayName: input.fullName,
      // The admin vouches for the address; the person can reset the password with it.
      emailVerified: true,
    })
    .catch((error: { code?: string }) => {
      if (error.code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "An account with this email already exists.");
      }
      throw error;
    });
  await auth.setCustomUserClaims(user.uid, { role: input.role, verified: true });

  const db = getFirestore();
  const batch = db.batch();
  batch.set(db.collection("users").doc(user.uid), {
    fullName: input.fullName,
    idNumber: null,
    email: input.email,
    phone: input.phone,
    role: input.role,
    verified: true,
    onDuty: false,
    fcmTokens: [],
    falseAlarmCount: 0,
    deactivated: false,
    createdAt: FieldValue.serverTimestamp(),
  });
  batch.set(
    db.collection("auditLogs").doc(),
    audit({ actorId, action: "user_created", target: user.uid, details: { email: input.email, role: input.role } }),
  );
  await batch.commit();

  logger.info("User created", { uid: user.uid, role: input.role, by: actorId });
  return { uid: user.uid };
});

/**
 * Changes a user's role and/or deactivates or reactivates them. The claim
 * is set first; the app notices the `users.role` change and refreshes its
 * token. Deactivating also disables sign-in and ends existing sessions.
 */
export const adminSetRole = onCall(async (request) => {
  const actorId = requireAdmin(request);
  const parsed = parseSetRoleInput(request.data, actorId);
  if (!parsed.ok) throw new HttpsError("invalid-argument", parsed.message);
  const input = parsed.value;

  const db = getFirestore();
  const userRef = db.collection("users").doc(input.uid);
  const current = (await userRef.get()).data();
  if (!current) throw new HttpsError("not-found", "This user no longer exists.");

  const entries = setRoleAuditEntries(actorId, input, current);
  if (entries.length === 0) return { changed: false };

  const auth = getAuth();
  const updates: Record<string, unknown> = {};
  if (input.role !== undefined && input.role !== current.role) {
    const existing = (await auth.getUser(input.uid)).customClaims ?? {};
    await auth.setCustomUserClaims(input.uid, { ...existing, role: input.role, verified: true });
    updates.role = input.role;
    updates.verified = true;
    if (input.role !== "officer" && input.role !== "admin") updates.onDuty = false;
  }
  if (input.deactivated !== undefined && input.deactivated !== (current.deactivated === true)) {
    await auth.updateUser(input.uid, { disabled: input.deactivated });
    if (input.deactivated) {
      await auth.revokeRefreshTokens(input.uid);
      updates.onDuty = false;
    }
    updates.deactivated = input.deactivated;
  }

  const batch = db.batch();
  batch.update(userRef, updates);
  for (const entry of entries) batch.set(db.collection("auditLogs").doc(), audit(entry));
  await batch.commit();

  logger.info("User updated", { uid: input.uid, actions: entries.map((e) => e.action), by: actorId });
  return { changed: true };
});

/**
 * Adds or updates `idRoster` entries from a CSV the dashboard has parsed.
 * Existing entries keep `claimedBy`, so re-importing next semester's list
 * doesn't unlink registered students.
 */
export const adminImportRoster = onCall(async (request) => {
  const actorId = requireAdmin(request);
  const parsed = parseRosterRows(request.data);
  if (!parsed.ok) throw new HttpsError("invalid-argument", parsed.message);
  const { valid, rejected } = parsed.value;

  const db = getFirestore();
  for (const rows of chunk(valid, 450)) {
    const batch = db.batch();
    for (const row of rows) {
      batch.set(
        db.collection("idRoster").doc(row.idNumber),
        { ...row, importedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    }
    await batch.commit();
  }
  await db
    .collection("auditLogs")
    .add(
      audit({
        actorId,
        action: "roster_imported",
        target: "idRoster",
        details: { imported: valid.length, rejected: rejected.length },
      }),
    );

  logger.info("Roster imported", { imported: valid.length, rejected: rejected.length, by: actorId });
  // Enough detail for the admin to fix the file without a huge response.
  return { imported: valid.length, rejectedCount: rejected.length, rejected: rejected.slice(0, 100) };
});

/**
 * Saves `settings/app` from the dashboard's settings page. Rules don't let
 * clients write settings directly, so every change is audited.
 */
export const adminUpdateSettings = onCall(async (request) => {
  const actorId = requireAdmin(request);
  const parsed = parseSettingsInput(request.data);
  if (!parsed.ok) throw new HttpsError("invalid-argument", parsed.message);
  const input = parsed.value;

  const db = getFirestore();
  const ref = db.collection("settings").doc("app");
  const changed = changedSettings((await ref.get()).data(), input);
  if (changed.length === 0) return { changed: [] };

  const point = (p: LatLng) => new GeoPoint(p.lat, p.lng);
  const batch = db.batch();
  batch.set(ref, {
    categories: input.categories,
    securityPhone: input.securityPhone,
    sosCountdownSec: input.sosCountdownSec,
    campusBoundary: input.campusBoundary.map(point),
    zones: input.zones.map((z) => ({ name: z.name, center: point(z.center), radiusM: z.radiusM })),
  });
  batch.set(
    db.collection("auditLogs").doc(),
    audit({ actorId, action: "settings_updated", target: "settings/app", details: { fields: changed } }),
  );
  await batch.commit();

  logger.info("Settings updated", { fields: changed, by: actorId });
  return { changed };
});
