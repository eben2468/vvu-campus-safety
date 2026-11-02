import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { changedSettings, parseSettingsInput } from "../../src/settingsLogic";

const valid = {
  categories: ["Theft", " Medical "],
  securityPhone: "+233302000000",
  sosCountdownSec: 3,
  campusBoundary: [
    { lat: 5.797, lng: -0.126 },
    { lat: 5.797, lng: -0.118 },
    { lat: 5.789, lng: -0.118 },
  ],
  zones: [{ name: "Hostels", center: { lat: 5.795, lng: -0.124 }, radiusM: 150.4 }],
};

describe("parseSettingsInput", () => {
  it("accepts valid settings and tidies them", () => {
    const parsed = parseSettingsInput(valid);
    assert.ok(parsed.ok);
    assert.deepEqual(parsed.value.categories, ["Theft", "Medical"]);
    assert.equal(parsed.value.zones[0].radiusM, 150);
  });

  it("rejects bad categories", () => {
    assert.equal(parseSettingsInput({ ...valid, categories: [] }).ok, false);
    assert.equal(parseSettingsInput({ ...valid, categories: ["Theft", "theft"] }).ok, false);
    assert.equal(parseSettingsInput({ ...valid, categories: ["Emergency"] }).ok, false);
  });

  it("rejects a bad phone, countdown, boundary or zone", () => {
    assert.equal(parseSettingsInput({ ...valid, securityPhone: "0302000000" }).ok, false);
    assert.equal(parseSettingsInput({ ...valid, sosCountdownSec: 11 }).ok, false);
    assert.equal(parseSettingsInput({ ...valid, sosCountdownSec: 2.5 }).ok, false);
    assert.equal(parseSettingsInput({ ...valid, campusBoundary: valid.campusBoundary.slice(0, 2) }).ok, false);
    assert.equal(parseSettingsInput({ ...valid, campusBoundary: [{ lat: 95, lng: 0 }, ...valid.campusBoundary] }).ok, false);
    assert.equal(parseSettingsInput({ ...valid, zones: [{ name: "Gate", center: { lat: 5.79, lng: -0.12 }, radiusM: 5 }] }).ok, false);
  });

  it("allows no boundary at all", () => {
    assert.ok(parseSettingsInput({ ...valid, campusBoundary: [] }).ok);
  });
});

describe("changedSettings", () => {
  it("lists only the fields that changed, treating GeoPoints like inputs", () => {
    const parsed = parseSettingsInput(valid);
    assert.ok(parsed.ok);
    const stored = {
      ...parsed.value,
      campusBoundary: parsed.value.campusBoundary.map((p) => ({ latitude: p.lat, longitude: p.lng })),
      zones: parsed.value.zones.map((z) => ({ ...z, center: { latitude: z.center.lat, longitude: z.center.lng } })),
    };
    assert.deepEqual(changedSettings(stored, parsed.value), []);
    assert.deepEqual(changedSettings({ ...stored, sosCountdownSec: 5 }, parsed.value), ["sosCountdownSec"]);
    assert.equal(changedSettings(undefined, parsed.value).length, 5);
  });
});
