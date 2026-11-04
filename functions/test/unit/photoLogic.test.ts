import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { canUploadPhoto, MAX_PHOTO_BYTES, parsePhotoUpload } from "../../src/photoLogic";

const jpeg = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(100)]);
const upload = (over: Record<string, unknown> = {}) => ({
  incidentId: "abc123",
  fileName: "photo_1.jpg",
  dataBase64: jpeg.toString("base64"),
  ...over,
});

describe("canUploadPhoto", () => {
  it("allows verified members and all security staff", () => {
    assert.equal(canUploadPhoto("student", true), true);
    assert.equal(canUploadPhoto("staff", true), true);
    assert.equal(canUploadPhoto("officer", false), true);
    assert.equal(canUploadPhoto("admin", true), true);
  });

  it("refuses unverified or unknown accounts", () => {
    assert.equal(canUploadPhoto("student", false), false);
    assert.equal(canUploadPhoto(undefined, true), false);
  });
});

describe("parsePhotoUpload", () => {
  it("accepts report and chat photos", () => {
    const report = parsePhotoUpload(upload());
    assert.ok(report.ok);
    assert.equal(report.value.path, "incidents/abc123/photo_1.jpg");
    assert.ok(parsePhotoUpload(upload({ fileName: "chat_m1-x.jpg" })).ok);
  });

  it("rejects paths that could escape the incident's folder", () => {
    assert.equal(parsePhotoUpload(upload({ incidentId: "../users" })).ok, false);
    assert.equal(parsePhotoUpload(upload({ fileName: "../../evil.jpg" })).ok, false);
    assert.equal(parsePhotoUpload(upload({ fileName: "video.mp4" })).ok, false);
  });

  it("rejects anything that isn't a JPEG (no video in the MVP)", () => {
    const notJpeg = Buffer.from("GIF89a-not-a-photo").toString("base64");
    assert.equal(parsePhotoUpload(upload({ dataBase64: notJpeg })).ok, false);
    assert.equal(parsePhotoUpload(upload({ dataBase64: "" })).ok, false);
  });

  it("rejects photos over the size limit", () => {
    const big = Buffer.concat([jpeg, Buffer.alloc(MAX_PHOTO_BYTES)]).toString("base64");
    assert.equal(parsePhotoUpload(upload({ dataBase64: big })).ok, false);
  });
});
