/**
 * Security rules tests for `users` and `idRoster`. Needs the Firestore
 * emulator — run from /functions with `npm run test:rules`.
 */
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { after, before, beforeEach, describe, it } from "node:test";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestContext,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { deleteDoc, doc, Firestore, getDoc, setDoc, updateDoc } from "firebase/firestore";

let env: RulesTestEnvironment;

const student = { role: "student", verified: true };
const officer = { role: "officer", verified: true };
const admin = { role: "admin", verified: true };

const profile = {
  fullName: "Kwame Mensah",
  idNumber: "223IT0100001",
  email: "kwame@example.com",
  phone: "+233241234567",
  role: "student",
  verified: true,
  onDuty: false,
  fcmTokens: [],
  falseAlarmCount: 0,
  deactivated: false,
};

function db(context: RulesTestContext): Firestore {
  return context.firestore() as unknown as Firestore;
}

const as = {
  kwame: () => db(env.authenticatedContext("kwame", student)),
  abena: () => db(env.authenticatedContext("abena", student)),
  officer: () => db(env.authenticatedContext("officer1", officer)),
  admin: () => db(env.authenticatedContext("admin1", admin)),
  anonymous: () => db(env.unauthenticatedContext()),
};

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-vvu-rules-test", // separate from the dev data
    firestore: { rules: readFileSync(resolve(process.cwd(), "..", "firestore.rules"), "utf8") },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const admin = db(context);
    await setDoc(doc(admin, "users/kwame"), profile);
    await setDoc(doc(admin, "users/officer1"), { ...profile, role: "officer", idNumber: null });
    await setDoc(doc(admin, "users/gone"), { ...profile, deactivated: true });
    await setDoc(doc(admin, "idRoster/223IT0100001"), { fullName: "Kwame Mensah", type: "student", active: true });
  });
});

describe("users", () => {
  it("lets a user read their own profile", async () => {
    await assertSucceeds(getDoc(doc(as.kwame(), "users/kwame")));
  });

  it("stops a student reading another user's profile", async () => {
    await assertFails(getDoc(doc(as.abena(), "users/kwame")));
  });

  it("lets officers read any profile", async () => {
    await assertSucceeds(getDoc(doc(as.officer(), "users/kwame")));
  });

  it("blocks signed-out reads", async () => {
    await assertFails(getDoc(doc(as.anonymous(), "users/kwame")));
  });

  it("lets a user change their phone number", async () => {
    await assertSucceeds(updateDoc(doc(as.kwame(), "users/kwame"), { phone: "+233501234567" }));
  });

  it("rejects a phone number that is not +233", async () => {
    await assertFails(updateDoc(doc(as.kwame(), "users/kwame"), { phone: "0241234567" }));
  });

  const protectedChanges: Record<string, unknown>[] = [
    { role: "admin" },
    { verified: false },
    { deactivated: true },
    { idNumber: "224BA0300042" },
    { falseAlarmCount: -1 },
    { fullName: "Someone Else" },
  ];
  for (const change of protectedChanges) {
    it(`stops a user changing their own ${Object.keys(change)[0]}`, async () => {
      await assertFails(updateDoc(doc(as.kwame(), "users/kwame"), change));
    });
  }

  it("stops a student going on duty", async () => {
    await assertFails(updateDoc(doc(as.kwame(), "users/kwame"), { onDuty: true }));
  });

  it("lets an officer go on duty", async () => {
    await assertSucceeds(updateDoc(doc(as.officer(), "users/officer1"), { onDuty: true }));
  });

  it("blocks updates from a deactivated user", async () => {
    const gone = db(env.authenticatedContext("gone", student));
    await assertFails(updateDoc(doc(gone, "users/gone"), { phone: "+233501234567" }));
  });

  it("stops clients creating or deleting profiles", async () => {
    await assertFails(setDoc(doc(as.abena(), "users/abena"), { ...profile, fullName: "Abena Owusu" }));
    await assertFails(deleteDoc(doc(as.kwame(), "users/kwame")));
  });

  it("stops one user editing another's profile", async () => {
    await assertFails(updateDoc(doc(as.abena(), "users/kwame"), { phone: "+233501234567" }));
  });
});

describe("idRoster", () => {
  it("is hidden from students and signed-out users", async () => {
    await assertFails(getDoc(doc(as.kwame(), "idRoster/223IT0100001")));
    await assertFails(getDoc(doc(as.anonymous(), "idRoster/223IT0100001")));
  });

  it("is hidden from officers", async () => {
    await assertFails(getDoc(doc(as.officer(), "idRoster/223IT0100001")));
  });

  it("can be read and written by admins", async () => {
    await assertSucceeds(getDoc(doc(as.admin(), "idRoster/223IT0100001")));
    await assertSucceeds(setDoc(doc(as.admin(), "idRoster/224BA0300042"), { fullName: "Kofi Asante", type: "student", active: true }));
  });

  it("cannot be claimed directly by a student", async () => {
    await assertFails(updateDoc(doc(as.kwame(), "idRoster/223IT0100001"), { claimedBy: "kwame" }));
  });
});

describe("other collections", () => {
  it("stay locked until their milestone", async () => {
    await assertFails(getDoc(doc(as.officer(), "announcements/any")));
    await assertFails(setDoc(doc(as.kwame(), "incidents/any"), { status: "new" }));
  });
});
