/**
 * Checks for `adminUpdateSettings` (docs/PRD.md §4.12). Pure functions with
 * no Firebase imports; unit tested in test/unit/settingsLogic.test.ts.
 */
import { Parsed } from "./adminLogic";
import { GHANA_PHONE_PATTERN } from "./roster";

export const MAX_CATEGORIES = 20;
export const MAX_ZONES = 30;
export const MAX_BOUNDARY_POINTS = 100;
export const MAX_COUNTDOWN_SEC = 10;

export interface LatLng {
  lat: number;
  lng: number;
}

export interface ZoneInput {
  name: string;
  center: LatLng;
  radiusM: number;
}

/** `settings/app`, with points as plain numbers (the function makes GeoPoints). */
export interface SettingsInput {
  categories: string[];
  securityPhone: string;
  sosCountdownSec: number;
  campusBoundary: LatLng[];
  zones: ZoneInput[];
}

export function parseSettingsInput(data: unknown): Parsed<SettingsInput> {
  const d = asRecord(data);

  if (!Array.isArray(d.categories)) return fail("Add at least one category.");
  const categories = d.categories.map((c) => (typeof c === "string" ? c.trim() : ""));
  if (categories.length === 0 || categories.length > MAX_CATEGORIES) {
    return fail(`Use between 1 and ${MAX_CATEGORIES} categories.`);
  }
  if (categories.some((c) => c.length === 0 || c.length > 40)) {
    return fail("Each category needs a name of up to 40 characters.");
  }
  const lower = categories.map((c) => c.toLowerCase());
  if (new Set(lower).size !== lower.length) return fail("Categories must not repeat.");
  if (lower.includes("emergency")) return fail("\"emergency\" is reserved for SOS alerts.");

  const securityPhone = typeof d.securityPhone === "string" ? d.securityPhone.trim() : "";
  if (!GHANA_PHONE_PATTERN.test(securityPhone)) return fail("Enter the Security Office number as +233…");

  const countdown = d.sosCountdownSec;
  if (typeof countdown !== "number" || !Number.isInteger(countdown) || countdown < 0 || countdown > MAX_COUNTDOWN_SEC) {
    return fail(`The SOS countdown must be 0 to ${MAX_COUNTDOWN_SEC} seconds.`);
  }

  if (!Array.isArray(d.campusBoundary)) return fail("The campus boundary is missing.");
  const boundary = d.campusBoundary.map(toLatLng);
  if (boundary.some((p) => p === null)) return fail("A boundary point is not a valid latitude and longitude.");
  if (boundary.length > MAX_BOUNDARY_POINTS || (boundary.length > 0 && boundary.length < 3)) {
    return fail(`The boundary needs 3 to ${MAX_BOUNDARY_POINTS} points, or none.`);
  }

  if (!Array.isArray(d.zones) || d.zones.length > MAX_ZONES) return fail(`Use at most ${MAX_ZONES} zones.`);
  const zones: ZoneInput[] = [];
  for (const raw of d.zones) {
    const z = asRecord(raw);
    const name = typeof z.name === "string" ? z.name.trim() : "";
    const center = toLatLng(z.center);
    const radiusM = z.radiusM;
    if (name.length === 0 || name.length > 60) return fail("Each zone needs a name of up to 60 characters.");
    if (!center) return fail(`Zone "${name}" needs a valid centre.`);
    if (typeof radiusM !== "number" || radiusM < 10 || radiusM > 2000) {
      return fail(`Zone "${name}" needs a radius of 10 to 2000 metres.`);
    }
    zones.push({ name, center, radiusM: Math.round(radiusM) });
  }

  return {
    ok: true,
    value: {
      categories,
      securityPhone,
      sosCountdownSec: countdown,
      campusBoundary: boundary as LatLng[],
      zones,
    },
  };
}

/** Top-level fields that differ, for the audit log. */
export function changedSettings(before: Record<string, unknown> | undefined, after: SettingsInput): string[] {
  const keys: (keyof SettingsInput)[] = ["categories", "securityPhone", "sosCountdownSec", "campusBoundary", "zones"];
  return keys.filter((key) => JSON.stringify(normalise(before?.[key])) !== JSON.stringify(normalise(after[key])));
}

/** GeoPoints (`latitude`/`longitude`) and inputs (`lat`/`lng`) compare equal. */
function normalise(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(normalise);
  if (typeof value === "object" && value !== null) {
    const v = value as Record<string, unknown>;
    if (typeof v.latitude === "number" && typeof v.longitude === "number") return { lat: v.latitude, lng: v.longitude };
    return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, normalise(x)]));
  }
  return value;
}

function toLatLng(value: unknown): LatLng | null {
  const v = asRecord(value);
  const { lat, lng } = v;
  if (typeof lat !== "number" || typeof lng !== "number") return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return { lat, lng };
}

function asRecord(data: unknown): Record<string, unknown> {
  return typeof data === "object" && data !== null ? (data as Record<string, unknown>) : {};
}

function fail<T>(message: string): Parsed<T> {
  return { ok: false, message };
}
