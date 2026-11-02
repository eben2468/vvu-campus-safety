/**
 * ID roster checks used by `verifyId`. Pure functions with no Firebase
 * imports, so they can be unit tested directly (test/unit/roster.test.ts).
 */

export type RosterType = "student" | "staff";

/** An `idRoster/{idNumber}` document (docs/ARCHITECTURE.md §3). */
export interface RosterEntry {
  idNumber: string;
  fullName: string;
  type: RosterType;
  department?: string;
  active: boolean;
  claimedBy?: string | null;
}

export interface VerifyIdInput {
  idNumber: string;
  fullName: string;
  phone: string;
}

/** HttpsError codes `verifyId` can fail with after reading the roster. */
export type RosterErrorCode =
  | "not-found"
  | "failed-precondition"
  | "permission-denied"
  | "already-exists";

export type RosterCheck =
  | { ok: true; entry: RosterEntry }
  | { ok: false; code: RosterErrorCode; message: string };

export const ID_NUMBER_PATTERN = /^[A-Z0-9]{6,20}$/;
export const GHANA_PHONE_PATTERN = /^\+233\d{9}$/;

/** Uppercase, no spaces. Must match `normalizeIdNumber` in the Flutter app. */
export function normalizeIdNumber(raw: string): string {
  return raw.replace(/\s+/g, "").toUpperCase();
}

/** Lower-case words of a name, ignoring punctuation and hyphens. */
export function nameWords(name: string): string[] {
  return name.toLowerCase().split(/[\s,.-]+/).filter(Boolean);
}

/**
 * The surname is the last word of the roster name. It must appear somewhere
 * in the name the user typed, ignoring case and word order.
 */
export function surnameMatches(rosterName: string, enteredName: string): boolean {
  const surname = nameWords(rosterName).at(-1);
  return surname !== undefined && nameWords(enteredName).includes(surname);
}

/** Validates the callable's input. Returns null if anything is missing or malformed. */
export function parseVerifyIdInput(data: unknown): VerifyIdInput | null {
  if (typeof data !== "object" || data === null) return null;
  const { idNumber, fullName, phone } = data as Record<string, unknown>;
  if (typeof idNumber !== "string" || typeof fullName !== "string" || typeof phone !== "string") {
    return null;
  }
  const input = {
    idNumber: normalizeIdNumber(idNumber),
    fullName: fullName.trim(),
    phone: phone.trim(),
  };
  if (!ID_NUMBER_PATTERN.test(input.idNumber)) return null;
  if (!GHANA_PHONE_PATTERN.test(input.phone)) return null;
  if (input.fullName.length === 0 || input.fullName.length > 100) return null;
  return input;
}

/**
 * Decides whether `uid` may claim the roster `entry` (docs/PRD.md §4.1).
 * An entry already claimed by the same uid passes, so a retry after a
 * partial failure succeeds.
 */
export function checkRosterEntry(
  entry: RosterEntry | undefined,
  uid: string,
  enteredName: string,
): RosterCheck {
  if (!entry) {
    return fail("not-found", "ID not found — contact the Security Office.");
  }
  if (!entry.active) {
    return fail("failed-precondition", "This ID is not active — contact the Security Office.");
  }
  // Name is checked before "claimed" so a guessed ID reveals as little as possible.
  if (!surnameMatches(entry.fullName, enteredName)) {
    return fail("permission-denied", "The name you entered doesn't match our records for this ID.");
  }
  if (entry.claimedBy && entry.claimedBy !== uid) {
    return fail(
      "already-exists",
      "This ID is already registered to another account. If it is yours, contact the Security Office.",
    );
  }
  return { ok: true, entry };
}

function fail(code: RosterErrorCode, message: string): RosterCheck {
  return { ok: false, code, message };
}
