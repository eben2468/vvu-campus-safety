/**
 * Input checks for the admin callables in admin.ts (docs/PRD.md §4.11).
 * Pure functions with no Firebase imports, so they can be unit tested
 * directly (test/unit/adminLogic.test.ts).
 */
import { GHANA_PHONE_PATTERN, ID_NUMBER_PATTERN, normalizeIdNumber, RosterType } from "./roster";

export type Role = "student" | "staff" | "officer" | "admin";
export const ROLES: readonly Role[] = ["student", "staff", "officer", "admin"];

/** The most roster rows one `adminImportRoster` call accepts. */
export const MAX_ROSTER_ROWS = 5000;
export const MIN_PASSWORD_LENGTH = 8;

export type Parsed<T> = { ok: true; value: T } | { ok: false; message: string };

export function isRole(value: unknown): value is Role {
  return typeof value === "string" && (ROLES as readonly string[]).includes(value);
}

export interface CreateUserInput {
  email: string;
  password: string;
  fullName: string;
  phone: string;
  role: "officer" | "admin";
}

/** Officers and admins are created by an admin; students and staff register themselves. */
export function parseCreateUserInput(data: unknown): Parsed<CreateUserInput> {
  const { email, password, fullName, phone, role } = asRecord(data);
  if (typeof email !== "string" || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
    return fail("Enter a valid email address.");
  }
  if (typeof password !== "string" || password.length < MIN_PASSWORD_LENGTH) {
    return fail(`The temporary password needs at least ${MIN_PASSWORD_LENGTH} characters.`);
  }
  if (typeof fullName !== "string" || fullName.trim().length === 0 || fullName.trim().length > 100) {
    return fail("Enter the person's full name.");
  }
  if (typeof phone !== "string" || !GHANA_PHONE_PATTERN.test(phone.trim())) {
    return fail("Enter a Ghana phone number (+233…).");
  }
  if (role !== "officer" && role !== "admin") {
    return fail("New accounts must be officers or admins.");
  }
  return {
    ok: true,
    value: { email: email.trim().toLowerCase(), password, fullName: fullName.trim(), phone: phone.trim(), role },
  };
}

export interface SetRoleInput {
  uid: string;
  role?: Role;
  deactivated?: boolean;
}

/**
 * Validates an `adminSetRole` call. [callerUid] is the admin making it:
 * admins may not change their own role or deactivate themselves, so the
 * dashboard can never be left without an admin by accident.
 */
export function parseSetRoleInput(data: unknown, callerUid: string): Parsed<SetRoleInput> {
  const { uid, role, deactivated } = asRecord(data);
  if (typeof uid !== "string" || uid.length === 0) return fail("Choose a user.");
  if (role !== undefined && !isRole(role)) return fail("Choose a valid role.");
  if (deactivated !== undefined && typeof deactivated !== "boolean") return fail("Choose active or deactivated.");
  if (role === undefined && deactivated === undefined) return fail("Nothing to change.");
  if (uid === callerUid) return fail("You can't change your own role or deactivate yourself.");
  return { ok: true, value: { uid, role, deactivated } };
}

/** One valid row of an imported roster CSV. */
export interface RosterRow {
  idNumber: string;
  fullName: string;
  type: RosterType;
  department: string;
  active: boolean;
}

export interface RejectedRow {
  /** Position in the uploaded list, counting from 1. */
  row: number;
  idNumber: string;
  reason: string;
}

export interface RosterRows {
  valid: RosterRow[];
  rejected: RejectedRow[];
}

/**
 * Checks each row of an `adminImportRoster` call. Bad rows are reported,
 * not fatal, so one typo doesn't block a 3000-line import. A repeated ID
 * keeps its first row.
 */
export function parseRosterRows(data: unknown): Parsed<RosterRows> {
  const { rows } = asRecord(data);
  if (!Array.isArray(rows) || rows.length === 0) return fail("The file has no rows to import.");
  if (rows.length > MAX_ROSTER_ROWS) return fail(`Import at most ${MAX_ROSTER_ROWS} rows at a time.`);

  const valid: RosterRow[] = [];
  const rejected: RejectedRow[] = [];
  const seen = new Set<string>();
  rows.forEach((raw, index) => {
    const row = asRecord(raw);
    const idNumber = typeof row.idNumber === "string" ? normalizeIdNumber(row.idNumber) : "";
    const reject = (reason: string): void => {
      rejected.push({ row: index + 1, idNumber, reason });
    };

    const fullName = typeof row.fullName === "string" ? row.fullName.trim() : "";
    const department = typeof row.department === "string" ? row.department.trim() : "";
    if (!ID_NUMBER_PATTERN.test(idNumber)) return reject("ID number must be 6–20 letters or digits.");
    if (fullName.length === 0 || fullName.length > 100) return reject("Full name is missing.");
    if (row.type !== "student" && row.type !== "staff") return reject("Type must be student or staff.");
    if (department.length > 100) return reject("Department is too long.");
    if (row.active !== undefined && typeof row.active !== "boolean") return reject("Active must be true or false.");
    if (seen.has(idNumber)) return reject("This ID appears earlier in the file.");

    seen.add(idNumber);
    valid.push({ idNumber, fullName, type: row.type, department, active: row.active !== false });
  });
  return { ok: true, value: { valid, rejected } };
}

/** Splits [items] into lists of at most [size] (Firestore batches take 500 writes). */
export function chunk<T>(items: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < items.length; i += size) chunks.push(items.slice(i, i + size));
  return chunks;
}

/** Fields of an `auditLogs` document, minus the server timestamp. */
export interface AuditEntry {
  actorId: string;
  action:
    | "user_created"
    | "role_changed"
    | "user_deactivated"
    | "user_reactivated"
    | "roster_imported"
    | "settings_updated";
  target: string;
  details: Record<string, unknown>;
}

/** The audit entries for one `adminSetRole` call, given the user's current state. */
export function setRoleAuditEntries(
  actorId: string,
  input: SetRoleInput,
  current: { role?: string; deactivated?: boolean },
): AuditEntry[] {
  const entries: AuditEntry[] = [];
  if (input.role !== undefined && input.role !== current.role) {
    entries.push({ actorId, action: "role_changed", target: input.uid, details: { from: current.role ?? null, to: input.role } });
  }
  if (input.deactivated !== undefined && input.deactivated !== (current.deactivated === true)) {
    entries.push({
      actorId,
      action: input.deactivated ? "user_deactivated" : "user_reactivated",
      target: input.uid,
      details: {},
    });
  }
  return entries;
}

function asRecord(data: unknown): Record<string, unknown> {
  return typeof data === "object" && data !== null ? (data as Record<string, unknown>) : {};
}

function fail<T>(message: string): Parsed<T> {
  return { ok: false, message };
}
