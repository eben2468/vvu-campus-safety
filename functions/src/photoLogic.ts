/** Checks on uploaded photos. No Firebase imports, so they can be unit tested. */

/** Above the app's 1 MB compression target, with room to spare. */
export const MAX_PHOTO_BYTES = 2 * 1024 * 1024;

export interface PhotoUpload {
  path: string;
  bytes: Buffer;
}

export type ParsedPhoto = { ok: true; value: PhotoUpload } | { ok: false; message: string };

/** Students, staff and security may upload; unverified accounts may not. */
export function canUploadPhoto(role: string | undefined, verified: boolean): boolean {
  if (role === "officer" || role === "admin") return true;
  return verified && (role === "student" || role === "staff");
}

/** True for JPEG data: the app re-encodes every photo as JPEG before upload. */
export function isJpeg(bytes: Buffer): boolean {
  return bytes.length > 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
}

/** True for a stored photo's path; anything else in the store, such as backups, is never served. */
export function isPhotoPath(path: string): boolean {
  return /^incidents\/[\w-]{1,128}\/[\w-]{1,200}\.jpg$/.test(path);
}

/** The API address that serves a stored photo. */
export function photoUrl(host: string, path: string): string {
  return `https://${host}/api/file?path=${encodeURIComponent(path)}`;
}

/** Validates an upload. Photos only (no video in the MVP), under 2 MB. */
export function parsePhotoUpload(data: unknown): ParsedPhoto {
  const { incidentId, fileName, dataBase64 } = (data ?? {}) as Record<string, unknown>;
  if (typeof incidentId !== "string" || !/^[\w-]{1,128}$/.test(incidentId)) {
    return { ok: false, message: "Missing or invalid incident." };
  }
  if (typeof fileName !== "string" || !/^(photo_\d{1,2}|chat_[\w-]{1,128})\.jpg$/.test(fileName)) {
    return { ok: false, message: "Invalid file name." };
  }
  if (typeof dataBase64 !== "string" || dataBase64.length === 0) {
    return { ok: false, message: "The photo is empty." };
  }
  const bytes = Buffer.from(dataBase64, "base64");
  if (bytes.length > MAX_PHOTO_BYTES) return { ok: false, message: "That photo is too large." };
  if (!isJpeg(bytes)) return { ok: false, message: "Only photos can be uploaded." };
  return { ok: true, value: { path: `incidents/${incidentId}/${fileName}`, bytes } };
}
