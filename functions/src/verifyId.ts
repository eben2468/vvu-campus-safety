import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { checkRosterEntry, parseVerifyIdInput, RosterEntry } from "./roster";

/**
 * Links a newly registered account to a VVU ID (docs/PRD.md §4.1).
 *
 * In one transaction: checks `idRoster/{idNumber}`, marks it `claimedBy` the
 * caller and creates `users/{uid}`. Then sets the `role` and `verified`
 * custom claims. The transaction stops two accounts claiming the same ID.
 */
export const verifyId = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in before verifying your ID.");
  }
  // Already verified (including officers and admins): nothing to do.
  if (auth.token.verified === true) {
    return { role: auth.token.role };
  }

  const input = parseVerifyIdInput(request.data);
  if (!input) {
    throw new HttpsError(
      "invalid-argument",
      "Enter your full name, VVU ID number and a Ghana phone number (+233…).",
    );
  }

  const db = getFirestore();
  const rosterRef = db.collection("idRoster").doc(input.idNumber);
  const userRef = db.collection("users").doc(auth.uid);

  const entry = await db.runTransaction(async (tx) => {
    const rosterSnap = await tx.get(rosterRef);
    const userSnap = await tx.get(userRef);

    const check = checkRosterEntry(
      rosterSnap.exists ? (rosterSnap.data() as RosterEntry) : undefined,
      auth.uid,
      input.fullName,
    );
    if (!check.ok) {
      throw new HttpsError(check.code, check.message);
    }

    tx.update(rosterRef, { claimedBy: auth.uid });
    if (!userSnap.exists) {
      tx.set(userRef, {
        fullName: check.entry.fullName, // the roster name is authoritative
        idNumber: input.idNumber,
        email: auth.token.email ?? "",
        phone: input.phone,
        role: check.entry.type,
        verified: true,
        onDuty: false,
        fcmTokens: [],
        falseAlarmCount: 0,
        deactivated: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    return check.entry;
  });

  await getAuth().setCustomUserClaims(auth.uid, { role: entry.type, verified: true });
  logger.info("ID verified", { uid: auth.uid, idNumber: input.idNumber, role: entry.type });

  return { role: entry.type, fullName: entry.fullName };
});
