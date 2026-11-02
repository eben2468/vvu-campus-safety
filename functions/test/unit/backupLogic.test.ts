import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { backupUri, defaultBucket } from "../../src/backupLogic";

describe("backup", () => {
  it("names the folder by the UTC (Accra) date", () => {
    assert.equal(
      backupUri("vvu-campus-safety.firebasestorage.app", new Date("2026-11-03T02:00:00Z")),
      "gs://vvu-campus-safety.firebasestorage.app/backups/2026-11-03",
    );
  });

  it("reads the default bucket from FIREBASE_CONFIG", () => {
    assert.equal(defaultBucket(JSON.stringify({ storageBucket: "b.appspot.com" })), "b.appspot.com");
    assert.equal(defaultBucket(undefined), undefined);
    assert.equal(defaultBucket("not json"), undefined);
  });
});
