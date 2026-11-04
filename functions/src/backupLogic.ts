import { createCipheriv, createDecipheriv, createHash, randomBytes } from "node:crypto";
import { gunzipSync, gzipSync } from "node:zlib";

import { GeoPoint, Timestamp } from "firebase-admin/firestore";

/**
 * Most documents one backup may read. Firestore's free plan allows 50,000
 * reads a day and stops serving the app beyond that, so a backup must never
 * use a large share of them.
 */
export const BACKUP_MAX_DOCS = 20000;

/** One document per path, e.g. `incidents/abc/events/xyz`. */
export type BackupDocs = Record<string, unknown>;

/** Where a day's backup is stored. */
export function backupPath(date: Date): string {
  return `backups/${date.toISOString().slice(0, 10)}.json.gz.enc`;
}

/** Turns Firestore values into plain JSON that [decodeValue] can restore. */
export function encodeValue(value: unknown): unknown {
  if (value instanceof Timestamp) return { __timestamp: value.toDate().toISOString() };
  if (value instanceof GeoPoint) return { __geopoint: [value.latitude, value.longitude] };
  if (Array.isArray(value)) return value.map(encodeValue);
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, encodeValue(v)]));
  }
  return value;
}

export function decodeValue(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(decodeValue);
  if (value !== null && typeof value === "object") {
    const map = value as Record<string, unknown>;
    if (typeof map.__timestamp === "string") return Timestamp.fromDate(new Date(map.__timestamp));
    if (Array.isArray(map.__geopoint)) return new GeoPoint(Number(map.__geopoint[0]), Number(map.__geopoint[1]));
    return Object.fromEntries(Object.entries(map).map(([k, v]) => [k, decodeValue(v)]));
  }
  return value;
}

const keyFrom = (passphrase: string) => createHash("sha256").update(passphrase).digest();

/**
 * Compresses and encrypts a backup (AES-256-GCM). Blob URLs are public to
 * anyone holding the link and a backup holds names and phone numbers, so
 * it is never stored readable. Layout: 12-byte IV, 16-byte tag, ciphertext.
 */
export function sealBackup(docs: BackupDocs, passphrase: string): Buffer {
  const iv = randomBytes(12);
  const cipher = createCipheriv("aes-256-gcm", keyFrom(passphrase), iv);
  const body = Buffer.concat([cipher.update(gzipSync(JSON.stringify(docs))), cipher.final()]);
  return Buffer.concat([iv, cipher.getAuthTag(), body]);
}

/** Reverses [sealBackup]; throws if the passphrase is wrong. */
export function openBackup(sealed: Buffer, passphrase: string): BackupDocs {
  const decipher = createDecipheriv("aes-256-gcm", keyFrom(passphrase), sealed.subarray(0, 12));
  decipher.setAuthTag(sealed.subarray(12, 28));
  const zipped = Buffer.concat([decipher.update(sealed.subarray(28)), decipher.final()]);
  return JSON.parse(gunzipSync(zipped).toString("utf8")) as BackupDocs;
}
