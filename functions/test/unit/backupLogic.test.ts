import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { GeoPoint, Timestamp } from "firebase-admin/firestore";

import { backupPath, decodeValue, encodeValue, openBackup, sealBackup } from "../../src/backupLogic";

describe("backupPath", () => {
  it("names each day's backup", () => {
    assert.equal(backupPath(new Date("2026-11-03T02:00:00Z")), "backups/2026-11-03.json.gz.enc");
  });
});

describe("encodeValue / decodeValue", () => {
  it("round-trips Firestore types inside nested data", () => {
    const original = {
      when: Timestamp.fromDate(new Date("2026-11-03T02:00:00.000Z")),
      where: new GeoPoint(5.79, -0.12),
      list: [{ at: new GeoPoint(1, 2) }],
      name: "Kwame",
      missing: null,
    };
    const restored = decodeValue(JSON.parse(JSON.stringify(encodeValue(original)))) as typeof original;
    assert.ok(restored.when.isEqual(original.when));
    assert.ok(restored.where.isEqual(original.where));
    assert.ok(restored.list[0].at.isEqual(original.list[0].at));
    assert.equal(restored.name, "Kwame");
    assert.equal(restored.missing, null);
  });
});

describe("sealBackup / openBackup", () => {
  const docs = { "users/a": { fullName: "Kwame Mensah", phone: "+233548811774" } };

  it("opens with the right passphrase", () => {
    assert.deepEqual(openBackup(sealBackup(docs, "secret"), "secret"), docs);
  });

  it("is not readable without it", () => {
    const sealed = sealBackup(docs, "secret");
    assert.ok(!sealed.toString("latin1").includes("Kwame"));
    assert.throws(() => openBackup(sealed, "wrong"));
  });
});
