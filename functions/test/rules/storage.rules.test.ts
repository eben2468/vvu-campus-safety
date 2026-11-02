/**
 * Storage rules tests for incident photos. Needs the Storage emulator —
 * run with `npm run test:rules`.
 */
import { randomUUID } from "node:crypto";
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
import { deleteObject, FirebaseStorage, getMetadata, ref, uploadBytes } from "firebase/storage";

let env: RulesTestEnvironment;

const member = { role: "student", verified: true };
const storage = (context: RulesTestContext) => context.storage() as unknown as FirebaseStorage;
const as = {
  kwame: () => storage(env.authenticatedContext("kwame", member)),
  abena: () => storage(env.authenticatedContext("abena", member)),
  unverified: () => storage(env.authenticatedContext("newbie", { role: "student" })),
  officer: () => storage(env.authenticatedContext("officer1", { role: "officer", verified: true })),
  anonymous: () => storage(env.unauthenticatedContext()),
};

const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]);
const photo = (reporterId: string, contentType = "image/jpeg") => ({
  contentType,
  customMetadata: { reporterId },
});
// A fresh path per test, so tests never depend on files left by others.
let path = "";

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-vvu-rules-test", // separate from the dev data
    storage: { rules: readFileSync(resolve(process.cwd(), "..", "storage.rules"), "utf8") },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  path = `incidents/${randomUUID()}/photo_1.jpg`;
  await env.clearStorage();
});

/** Puts kwame's photo in place, bypassing rules. */
async function seedPhoto() {
  await env.withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(storage(context), path), jpeg, photo("kwame"));
  });
}

describe("uploading incident photos", () => {
  it("is allowed for a verified member tagging themselves", async () => {
    await assertSucceeds(uploadBytes(ref(as.kwame(), path), jpeg, photo("kwame")));
  });

  it("must be tagged with the uploader's own uid", async () => {
    await assertFails(uploadBytes(ref(as.kwame(), path), jpeg, photo("abena")));
  });

  it("must be an image (no video in the MVP)", async () => {
    await assertFails(uploadBytes(ref(as.kwame(), path), jpeg, photo("kwame", "video/mp4")));
  });

  it("must be under 2 MB", async () => {
    const big = new Uint8Array(2 * 1024 * 1024 + 1);
    await assertFails(uploadBytes(ref(as.kwame(), path), big, photo("kwame")));
  });

  it("is refused before the ID is verified, or signed out", async () => {
    await assertFails(uploadBytes(ref(as.unverified(), path), jpeg, photo("newbie")));
    await assertFails(uploadBytes(ref(as.anonymous(), path), jpeg, photo("anyone")));
  });

  it("cannot replace or delete existing evidence", async () => {
    await seedPhoto();
    await assertFails(uploadBytes(ref(as.kwame(), path), jpeg, photo("kwame")));
    await assertFails(deleteObject(ref(as.kwame(), path)));
  });
});

describe("viewing incident photos", () => {
  beforeEach(seedPhoto);

  it("is allowed for the reporter and officers", async () => {
    await assertSucceeds(getMetadata(ref(as.kwame(), path)));
    await assertSucceeds(getMetadata(ref(as.officer(), path)));
  });

  it("is refused for other students and signed-out users", async () => {
    await assertFails(getMetadata(ref(as.abena(), path)));
    await assertFails(getMetadata(ref(as.anonymous(), path)));
  });
});

describe("other paths", () => {
  it("are locked", async () => {
    await assertFails(uploadBytes(ref(as.kwame(), "profile/kwame.jpg"), jpeg, photo("kwame")));
  });
});
