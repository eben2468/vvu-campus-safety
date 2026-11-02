/**
 * Security rules tests for incidents, their locations and events, and
 * settings. Needs the Firestore emulator — run with `npm run test:rules`.
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
import {
  addDoc,
  arrayUnion,
  collection,
  doc,
  Firestore,
  GeoPoint,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from "firebase/firestore";

let env: RulesTestEnvironment;

const member = { role: "student", verified: true };
const db = (context: RulesTestContext) => context.firestore() as unknown as Firestore;
const as = {
  kwame: () => db(env.authenticatedContext("kwame", member)),
  abena: () => db(env.authenticatedContext("abena", member)),
  unverified: () => db(env.authenticatedContext("newbie", { role: "student" })),
  gone: () => db(env.authenticatedContext("gone", member)),
  officer: () => db(env.authenticatedContext("officer1", { role: "officer", verified: true })),
  officer2: () => db(env.authenticatedContext("officer2", { role: "officer", verified: true })),
  admin: () => db(env.authenticatedContext("admin1", { role: "admin", verified: true })),
};

const campus = new GeoPoint(5.793, -0.122);

/** An SOS as `IncidentRepository.createSos` writes it. */
function newSos(reporterId = "kwame") {
  return {
    kind: "sos",
    category: "emergency",
    description: "",
    status: "new",
    reporterId,
    reporterName: "Kwame Mensah",
    reporterPhone: "+233241234567",
    location: campus,
    geohash: "ebzz",
    lastLocation: campus,
    locationLabel: "Hostels",
    mediaUrls: [],
    assignedTo: [],
    createdAt: serverTimestamp(),
    active: true,
    cancelledByReporter: false,
  };
}

/** Puts an existing incident in place, bypassing rules. */
async function seedIncident(id: string, fields: Record<string, unknown>) {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(db(context), `incidents/${id}`), {
      ...newSos(),
      createdAt: new Date(),
      ...fields,
    });
  });
}

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
    await setDoc(doc(db(context), "users/kwame"), { deactivated: false });
    await setDoc(doc(db(context), "users/gone"), { deactivated: true });
    await setDoc(doc(db(context), "settings/app"), { securityPhone: "+233000000000" });
  });
});

describe("creating an SOS", () => {
  it("is allowed for a verified member", async () => {
    await assertSucceeds(setDoc(doc(as.kwame(), "incidents/s1"), newSos()));
  });

  it("works without a location", async () => {
    await assertSucceeds(
      setDoc(doc(as.kwame(), "incidents/s1"), { ...newSos(), location: null, lastLocation: null, geohash: null }),
    );
  });

  it("is refused for someone else's uid", async () => {
    await assertFails(setDoc(doc(as.abena(), "incidents/s1"), newSos("kwame")));
  });

  it("is refused before the ID is verified", async () => {
    await assertFails(setDoc(doc(as.unverified(), "incidents/s1"), newSos("newbie")));
  });

  it("is refused for a deactivated user", async () => {
    await assertFails(setDoc(doc(as.gone(), "incidents/s1"), newSos("gone")));
  });

  it("must start as new, unassigned and active", async () => {
    await assertFails(setDoc(doc(as.kwame(), "incidents/s1"), { ...newSos(), status: "accepted" }));
    await assertFails(setDoc(doc(as.kwame(), "incidents/s1"), { ...newSos(), assignedTo: ["kwame"] }));
    await assertFails(setDoc(doc(as.kwame(), "incidents/s1"), { ...newSos(), active: false }));
  });

  it("rejects extra fields and client-chosen times", async () => {
    await assertFails(setDoc(doc(as.kwame(), "incidents/s1"), { ...newSos(), responseSeconds: 1 }));
    await assertFails(setDoc(doc(as.kwame(), "incidents/s1"), { ...newSos(), createdAt: new Date(2020, 0, 1) }));
  });

  it("is refused for officers (they don't raise SOS)", async () => {
    await assertFails(setDoc(doc(as.officer(), "incidents/s1"), newSos("officer1")));
  });
});

describe("creating a report", () => {
  const report = (fields: Record<string, unknown> = {}) => ({
    ...newSos(),
    kind: "report",
    category: "Theft",
    description: "My laptop was taken from the library.",
    mediaUrls: ["https://example.com/photo_1.jpg"],
    ...fields,
  });

  it("is allowed with a description and up to 3 photos", async () => {
    await assertSucceeds(setDoc(doc(as.kwame(), "incidents/r1"), report()));
    await assertSucceeds(setDoc(doc(as.kwame(), "incidents/r2"), report({ mediaUrls: ["a", "b", "c"] })));
  });

  it("needs a 10–1000 character description", async () => {
    await assertFails(setDoc(doc(as.kwame(), "incidents/r1"), report({ description: "Too short" })));
    await assertFails(setDoc(doc(as.kwame(), "incidents/r1"), report({ description: "x".repeat(1001) })));
  });

  it("allows at most 3 photos", async () => {
    await assertFails(setDoc(doc(as.kwame(), "incidents/r1"), report({ mediaUrls: ["a", "b", "c", "d"] })));
  });
});

describe("reading incidents", () => {
  beforeEach(async () => {
    await seedIncident("s1", { reporterId: "kwame" });
  });

  it("lets the reporter and officers read it", async () => {
    await assertSucceeds(getDoc(doc(as.kwame(), "incidents/s1")));
    await assertSucceeds(getDoc(doc(as.officer(), "incidents/s1")));
  });

  it("stops another student reading it", async () => {
    await assertFails(getDoc(doc(as.abena(), "incidents/s1")));
  });

  it("allows a reporter's query for their own incidents only", async () => {
    await assertSucceeds(getDocs(query(collection(as.kwame(), "incidents"), where("reporterId", "==", "kwame"))));
    await assertFails(getDocs(query(collection(as.abena(), "incidents"), where("active", "==", true))));
  });

  it("allows the officer queue query", async () => {
    await assertSucceeds(getDocs(query(collection(as.officer(), "incidents"), where("active", "==", true))));
  });
});

describe("reporter updates", () => {
  it("can share a new position while active", async () => {
    await seedIncident("s1", { status: "alerted" });
    await assertSucceeds(updateDoc(doc(as.kwame(), "incidents/s1"), { lastLocation: new GeoPoint(5.794, -0.121) }));
  });

  it("cannot share a position after it closes", async () => {
    await seedIncident("s1", { status: "resolved", active: false });
    await assertFails(updateDoc(doc(as.kwame(), "incidents/s1"), { lastLocation: campus }));
  });

  const cancel = () => ({
    status: "resolved",
    cancelledByReporter: true,
    resolvedAt: serverTimestamp(),
    active: false,
  });

  it("can cancel (I'm safe) before an officer accepts", async () => {
    await seedIncident("s1", { status: "alerted" });
    await assertSucceeds(updateDoc(doc(as.kwame(), "incidents/s1"), cancel()));
  });

  it("cannot cancel once an officer has accepted", async () => {
    await seedIncident("s1", { status: "accepted", assignedTo: ["officer1"] });
    await assertFails(updateDoc(doc(as.kwame(), "incidents/s1"), cancel()));
  });

  it("cannot change the status in other ways", async () => {
    await seedIncident("s1", { status: "alerted" });
    await assertFails(updateDoc(doc(as.kwame(), "incidents/s1"), { status: "accepted" }));
    await assertFails(updateDoc(doc(as.kwame(), "incidents/s1"), { assignedTo: ["kwame"] }));
  });

  it("cannot touch another student's incident", async () => {
    await seedIncident("s1", { status: "alerted" });
    await assertFails(updateDoc(doc(as.abena(), "incidents/s1"), { lastLocation: campus }));
  });
});

describe("officer updates", () => {
  const accept = (uid: string) => ({
    status: "accepted",
    assignedTo: arrayUnion(uid),
    acknowledgedAt: serverTimestamp(),
  });

  it("can accept an alerted incident", async () => {
    await seedIncident("s1", { status: "alerted" });
    await assertSucceeds(updateDoc(doc(as.officer(), "incidents/s1"), accept("officer1")));
  });

  it("must assign themselves when accepting", async () => {
    await seedIncident("s1", { status: "alerted" });
    await assertFails(updateDoc(doc(as.officer(), "incidents/s1"), accept("officer2")));
  });

  it("cannot skip the state machine", async () => {
    await seedIncident("s1", { status: "new" });
    await assertFails(updateDoc(doc(as.officer(), "incidents/s1"), accept("officer1")));
    await seedIncident("s2", { status: "resolved", active: false });
    await assertFails(updateDoc(doc(as.officer(), "incidents/s2"), { status: "on_scene" }));
  });

  it("cannot rewrite reporter details or computed fields", async () => {
    await seedIncident("s1", { status: "alerted" });
    await assertFails(updateDoc(doc(as.officer(), "incidents/s1"), { reporterName: "Someone" }));
    await assertFails(updateDoc(doc(as.officer(), "incidents/s1"), { responseSeconds: 1 }));
  });

  it("works for admins too", async () => {
    await seedIncident("s1", { status: "alerted" });
    await assertSucceeds(updateDoc(doc(as.admin(), "incidents/s1"), accept("admin1")));
  });
});

describe("locations", () => {
  const fix = () => ({ point: campus, accuracy: 8, timestamp: serverTimestamp() });

  it("are written by the reporter while active", async () => {
    await seedIncident("s1", { status: "alerted" });
    await assertSucceeds(addDoc(collection(as.kwame(), "incidents/s1/locations"), fix()));
  });

  it("stop being accepted once the incident closes", async () => {
    await seedIncident("s1", { status: "resolved", active: false });
    await assertFails(addDoc(collection(as.kwame(), "incidents/s1/locations"), fix()));
  });

  it("cannot be written by anyone else", async () => {
    await seedIncident("s1", { status: "alerted" });
    await assertFails(addDoc(collection(as.abena(), "incidents/s1/locations"), fix()));
    await assertFails(addDoc(collection(as.officer(), "incidents/s1/locations"), fix()));
  });

  it("are readable by officers and the reporter only", async () => {
    await seedIncident("s1", { status: "alerted" });
    await assertSucceeds(getDocs(collection(as.officer(), "incidents/s1/locations")));
    await assertSucceeds(getDocs(collection(as.kwame(), "incidents/s1/locations")));
    await assertFails(getDocs(collection(as.abena(), "incidents/s1/locations")));
  });
});

describe("events", () => {
  const event = (type: string, actorId: string) => ({
    type,
    actorId,
    actorName: "Test",
    text: "",
    timestamp: serverTimestamp(),
  });

  beforeEach(async () => {
    await seedIncident("s1", { status: "alerted" });
  });

  it("officers record their own actions", async () => {
    await assertSucceeds(addDoc(collection(as.officer(), "incidents/s1/events"), event("accepted", "officer1")));
  });

  it("no one can write an event as someone else", async () => {
    await assertFails(addDoc(collection(as.officer(), "incidents/s1/events"), event("accepted", "officer2")));
  });

  it("reporters may only record a cancel", async () => {
    await assertSucceeds(addDoc(collection(as.kwame(), "incidents/s1/events"), event("cancelled", "kwame")));
    await assertFails(addDoc(collection(as.kwame(), "incidents/s1/events"), event("resolved", "kwame")));
  });

  it("system events can't be faked by clients", async () => {
    await assertFails(addDoc(collection(as.officer(), "incidents/s1/events"), event("alerted", "officer1")));
  });

  it("are hidden from other students", async () => {
    await assertFails(getDocs(collection(as.abena(), "incidents/s1/events")));
  });
});

describe("settings", () => {
  it("are readable by any signed-in user", async () => {
    await assertSucceeds(getDoc(doc(as.kwame(), "settings/app")));
  });

  it("can only be changed by admins", async () => {
    await assertFails(updateDoc(doc(as.officer(), "settings/app"), { securityPhone: "+233111111111" }));
    await assertSucceeds(updateDoc(doc(as.admin(), "settings/app"), { securityPhone: "+233111111111" }));
  });
});
