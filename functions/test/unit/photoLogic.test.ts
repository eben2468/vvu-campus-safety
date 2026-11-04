import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { canUploadPhoto, isPhotoPath, MAX_PHOTO_BYTES, parsePhotoUpload, photoUrl } from "../../src/photoLogic";
import { hasBlobStore } from "../../src/photoStore";

describe("hasBlobStore", () => {
  it("is true for a connected store and for a read-write token", () => {
    assert.equal(hasBlobStore({ BLOB_STORE_ID: "store_1" }), true);
    assert.equal(hasBlobStore({ BLOB_READ_WRITE_TOKEN: "token" }), true);
  });

  it("is false locally, so development uses the local folder", () => {
    assert.equal(hasBlobStore({}), false);
  });
});

const jpeg = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(100)]);
const upload = (over: Record<string, unknown> = {}) => ({
  incidentId: "abc123",
  fileName: "photo_1.jpg",
  dataBase64: jpeg.toString("base64"),
  ...over,
});

describe("isPhotoPath", () => {
  it("accepts stored report and chat photos, with their random suffix", () => {
    assert.equal(isPhotoPath("incidents/abc123/photo_1-Xy9kQ2mN.jpg"), true);
    assert.equal(isPhotoPath("incidents/abc123/chat_m1-x-Xy9kQ2mN.jpg"), true);
  });

  it("never serves backups or paths that leave the folder", () => {
    assert.equal(isPhotoPath("backups/2026-11-04.json.gz.enc"), false);
    assert.equal(isPhotoPath("incidents/../backups/x.jpg"), false);
    assert.equal(isPhotoPath("incidents/abc123/../../x.jpg"), false);
    assert.equal(isPhotoPath(""), false);
  });
});

describe("photoUrl", () => {
  it("points at the API with the path escaped", () => {
    assert.equal(
      photoUrl("api.example.com", "incidents/a/photo_1-x.jpg"),
      "https://api.example.com/api/file?path=incidents%2Fa%2Fphoto_1-x.jpg",
    );
  });
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
