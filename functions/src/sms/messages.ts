/**
 * Emergency-contact SMS on SOS (docs/PRD.md §4.10). Pure functions, unit
 * tested in test/unit/sms.test.ts.
 */
import { GHANA_PHONE_PATTERN } from "../roster";

/** At most this many contacts are texted (PRD: up to 5 contacts). */
export const MAX_CONTACTS = 5;

export interface Point {
  latitude: number;
  longitude: number;
}

/** Valid, distinct Ghana numbers from the contacts' `phone` fields, at most [MAX_CONTACTS]. */
export function contactNumbers(contacts: { phone?: unknown }[]): string[] {
  const numbers: string[] = [];
  for (const { phone } of contacts) {
    if (typeof phone !== "string" || !GHANA_PHONE_PATTERN.test(phone)) continue;
    if (!numbers.includes(phone)) numbers.push(phone);
    if (numbers.length === MAX_CONTACTS) break;
  }
  return numbers;
}

/** The text each contact receives. Kept short to fit in about two SMS parts. */
export function sosSmsText(reporterName: string, point?: Point | null): string {
  const where = point
    ? `Location: https://maps.google.com/?q=${point.latitude.toFixed(6)},${point.longitude.toFixed(6)}`
    : "Their location is not known yet.";
  return `VVU Campus Safety: ${reporterName} has pressed SOS on campus. Campus security has been alerted. ${where}`;
}
