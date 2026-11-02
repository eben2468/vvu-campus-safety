import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  checkRosterEntry,
  normalizeIdNumber,
  parseVerifyIdInput,
  RosterEntry,
  surnameMatches,
} from "../../src/roster";

const entry: RosterEntry = {
  idNumber: "223IT0100001",
  fullName: "Kwame Mensah",
  type: "student",
  department: "Information Technology",
  active: true,
};

describe("normalizeIdNumber", () => {
  it("uppercases and removes spaces", () => {
    assert.equal(normalizeIdNumber(" 223it 0100001 "), "223IT0100001");
  });
});

describe("surnameMatches", () => {
  it("ignores case and word order", () => {
    assert.ok(surnameMatches("Kwame Mensah", "MENSAH kwame"));
  });

  it("handles hyphenated surnames", () => {
    assert.ok(surnameMatches("Ezekiel Agoe-Kumah", "Ezekiel Agoe-Kumah"));
  });

  it("rejects a different surname", () => {
    assert.equal(surnameMatches("Kwame Mensah", "Kwame Asante"), false);
  });
});

describe("parseVerifyIdInput", () => {
  const valid = { idNumber: "223it0100001", fullName: " Kwame Mensah ", phone: "+233241234567" };

  it("normalises a valid request", () => {
    assert.deepEqual(parseVerifyIdInput(valid), {
      idNumber: "223IT0100001",
      fullName: "Kwame Mensah",
      phone: "+233241234567",
    });
  });

  it("rejects a non-Ghana phone number", () => {
    assert.equal(parseVerifyIdInput({ ...valid, phone: "0241234567" }), null);
  });

  it("rejects an ID with a slash (would break the document path)", () => {
    assert.equal(parseVerifyIdInput({ ...valid, idNumber: "223/IT/01" }), null);
  });

  it("rejects missing fields", () => {
    assert.equal(parseVerifyIdInput({ idNumber: "223IT0100001" }), null);
    assert.equal(parseVerifyIdInput(null), null);
  });
});

describe("checkRosterEntry", () => {
  it("accepts an active, unclaimed ID with a matching surname", () => {
    assert.deepEqual(checkRosterEntry(entry, "uid-1", "Kwame Mensah"), { ok: true, entry });
  });

  it("rejects an unknown ID", () => {
    const result = checkRosterEntry(undefined, "uid-1", "Kwame Mensah");
    assert.equal(result.ok, false);
    assert.equal(!result.ok && result.code, "not-found");
  });

  it("rejects an inactive ID", () => {
    const result = checkRosterEntry({ ...entry, active: false }, "uid-1", "Kwame Mensah");
    assert.equal(!result.ok && result.code, "failed-precondition");
  });

  it("rejects a name that does not match", () => {
    const result = checkRosterEntry(entry, "uid-1", "Kofi Asante");
    assert.equal(!result.ok && result.code, "permission-denied");
  });

  it("rejects an ID claimed by another account", () => {
    const result = checkRosterEntry({ ...entry, claimedBy: "uid-2" }, "uid-1", "Kwame Mensah");
    assert.equal(!result.ok && result.code, "already-exists");
  });

  it("lets the same account retry", () => {
    const result = checkRosterEntry({ ...entry, claimedBy: "uid-1" }, "uid-1", "Kwame Mensah");
    assert.equal(result.ok, true);
  });
});
