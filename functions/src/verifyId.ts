import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

import { ApiError } from "./api/errors";
import { ApiRequest, requireCaller } from "./api/request";
import { checkRosterEntry, parseVerifyIdInput, RosterEntry } from "./roster";

/**
 * Links a newly registered account to a VVU ID (docs/PRD.md §4.1).
 *
 * In one transaction: checks `idRoster/{idNumber}`, marks it `claimedBy` the
 * caller and creates `users/{uid}`. Then sets the `role` and `verified`
 * custom claims. The transaction stops two accounts claiming the same ID.
 */
export async function verifyId(request: ApiRequest) {
  const caller = requireCaller(request, "Sign in before verifying your ID.");
  // Already verified (including officers and admins): nothing to do.
  if (caller.verified) {
    return { role: caller.role };
  }

  const input = parseVerifyIdInput(request.data);
  if (!input) {
    throw new ApiError("invalid-argument", "Enter your full name, VVU ID number and a Ghana phone number (+233…).");
  }

  const db = getFirestore();
  const rosterRef = db.collection("idRoster").doc(input.idNumber);
  const userRef = db.collection("users").doc(caller.uid);

  const entry = await db.runTransaction(async (tx) => {
    const rosterSnap = await tx.get(rosterRef);
    const userSnap = await tx.get(userRef);

    const check = checkRosterEntry(
      rosterSnap.exists ? (rosterSnap.data() as RosterEntry) : undefined,
      caller.uid,
      input.fullName,
    );
    if (!check.ok) {
      throw new ApiError(check.code, check.message);
    }

    tx.update(rosterRef, { claimedBy: caller.uid });
    if (!userSnap.exists) {
      tx.set(userRef, {
        fullName: check.entry.fullName, // the roster name is authoritative
        idNumber: input.idNumber,
        email: caller.email ?? "",
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

  await getAuth().setCustomUserClaims(caller.uid, { role: entry.type, verified: true });
  console.info("ID verified", { uid: caller.uid, idNumber: input.idNumber, role: entry.type });

  return { role: entry.type, fullName: entry.fullName };
}
