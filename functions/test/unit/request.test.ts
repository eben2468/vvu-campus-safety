import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { ApiError } from "../../src/api/errors";
import { documentId, requireAdmin, requireCaller } from "../../src/api/request";

const student = { uid: "s1", role: "student", verified: true };
const admin = { uid: "a1", role: "admin", verified: true };

describe("requireCaller", () => {
  it("returns a signed-in caller and rejects anyone else", () => {
    assert.equal(requireCaller({ caller: student, data: null }).uid, "s1");
    assert.throws(
      () => requireCaller({ caller: null, data: null }),
      (e: ApiError) => e.code === "unauthenticated" && e.httpStatus === 401,
    );
  });
});

describe("requireAdmin", () => {
  it("only lets admins through", () => {
    assert.equal(requireAdmin({ caller: admin, data: null }), "a1");
    assert.throws(
      () => requireAdmin({ caller: student, data: null }),
      (e: ApiError) => e.code === "permission-denied" && e.httpStatus === 403,
    );
  });
});

describe("documentId", () => {
  it("accepts Firestore ids", () => {
    assert.equal(documentId({ incidentId: "AbC_12-x" }, "incidentId"), "AbC_12-x");
  });

  it("rejects missing ids and path tricks", () => {
    for (const bad of [undefined, "", "a/b", "../x", 7]) {
      assert.throws(() => documentId({ incidentId: bad }, "incidentId"), ApiError);
    }
  });
});
