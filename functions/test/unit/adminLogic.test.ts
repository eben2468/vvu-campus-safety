import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  chunk,
  MAX_ROSTER_ROWS,
  parseCreateUserInput,
  parseRosterRows,
  parseSetRoleInput,
  setRoleAuditEntries,
} from "../../src/adminLogic";

const newOfficer = {
  email: " Kojo.Officer@VVU.edu.gh ",
  password: "temporary1",
  fullName: " Kojo Nyarko ",
  phone: "+233241112222",
  role: "officer",
};

describe("parseCreateUserInput", () => {
  it("accepts an officer and tidies the email and name", () => {
    const parsed = parseCreateUserInput(newOfficer);
    assert.ok(parsed.ok);
    assert.equal(parsed.value.email, "kojo.officer@vvu.edu.gh");
    assert.equal(parsed.value.fullName, "Kojo Nyarko");
  });

  it("rejects students, short passwords and bad phones", () => {
    assert.equal(parseCreateUserInput({ ...newOfficer, role: "student" }).ok, false);
    assert.equal(parseCreateUserInput({ ...newOfficer, password: "short" }).ok, false);
    assert.equal(parseCreateUserInput({ ...newOfficer, phone: "0241112222" }).ok, false);
    assert.equal(parseCreateUserInput({ ...newOfficer, email: "not-an-email" }).ok, false);
    assert.equal(parseCreateUserInput(null).ok, false);
  });
});

describe("parseSetRoleInput", () => {
  it("accepts a role change or a deactivation", () => {
    assert.ok(parseSetRoleInput({ uid: "u1", role: "officer" }, "admin1").ok);
    assert.ok(parseSetRoleInput({ uid: "u1", deactivated: true }, "admin1").ok);
  });

  it("rejects unknown roles and empty changes", () => {
    assert.equal(parseSetRoleInput({ uid: "u1", role: "guard" }, "admin1").ok, false);
    assert.equal(parseSetRoleInput({ uid: "u1" }, "admin1").ok, false);
    assert.equal(parseSetRoleInput({ uid: "u1", deactivated: "yes" }, "admin1").ok, false);
  });

  it("stops admins changing their own account", () => {
    const parsed = parseSetRoleInput({ uid: "admin1", deactivated: true }, "admin1");
    assert.equal(parsed.ok, false);
  });
});

describe("parseRosterRows", () => {
  const row = { idNumber: "223it 0100099", fullName: "Esi Quaye", type: "student", department: "Nursing" };

  it("normalises IDs and defaults active to true", () => {
    const parsed = parseRosterRows({ rows: [row] });
    assert.ok(parsed.ok);
    assert.deepEqual(parsed.value.valid, [
      { idNumber: "223IT0100099", fullName: "Esi Quaye", type: "student", department: "Nursing", active: true },
    ]);
  });

  it("reports bad and repeated rows without failing the import", () => {
    const parsed = parseRosterRows({
      rows: [row, { ...row, fullName: "Esi Q." }, { ...row, idNumber: "12" }, { ...row, idNumber: "STF00099", type: "visitor" }],
    });
    assert.ok(parsed.ok);
    assert.equal(parsed.value.valid.length, 1);
    assert.deepEqual(
      parsed.value.rejected.map((r) => r.row),
      [2, 3, 4],
    );
    assert.match(parsed.value.rejected[0].reason, /earlier/);
  });

  it("rejects empty and oversized uploads", () => {
    assert.equal(parseRosterRows({ rows: [] }).ok, false);
    assert.equal(parseRosterRows({}).ok, false);
    assert.equal(parseRosterRows({ rows: new Array(MAX_ROSTER_ROWS + 1).fill(row) }).ok, false);
  });
});

describe("chunk", () => {
  it("splits into batch-sized pieces", () => {
    assert.deepEqual(chunk([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
    assert.deepEqual(chunk([], 2), []);
  });
});

describe("setRoleAuditEntries", () => {
  it("records only what actually changes", () => {
    const entries = setRoleAuditEntries(
      "admin1",
      { uid: "u1", role: "officer", deactivated: false },
      { role: "staff", deactivated: false },
    );
    assert.deepEqual(entries, [
      { actorId: "admin1", action: "role_changed", target: "u1", details: { from: "staff", to: "officer" } },
    ]);
  });

  it("records deactivation and reactivation", () => {
    assert.equal(setRoleAuditEntries("a", { uid: "u1", deactivated: true }, {})[0].action, "user_deactivated");
    assert.equal(
      setRoleAuditEntries("a", { uid: "u1", deactivated: false }, { deactivated: true })[0].action,
      "user_reactivated",
    );
    assert.deepEqual(setRoleAuditEntries("a", { uid: "u1", role: "student" }, { role: "student" }), []);
  });
});
