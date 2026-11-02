/**
 * Decisions for chat and announcement pushes. Pure functions, unit tested
 * in test/unit/chatLogic.test.ts.
 */
import { IncidentDoc, PushContent } from "./incidentLogic";

export const AUDIENCES = ["all", "students", "staff", "officers"] as const;
export type Audience = (typeof AUDIENCES)[number];

export function isAudience(value: unknown): value is Audience {
  return typeof value === "string" && (AUDIENCES as readonly string[]).includes(value);
}

/** A reporter's message goes to security; security's goes to the reporter. */
export function messageAudience(senderId: string, incident: IncidentDoc): "reporter" | "security" {
  return senderId === incident.reporterId ? "security" : "reporter";
}

/** Shortens text for a notification, cutting at a word where possible. */
export function preview(text: string, max = 120): string {
  const clean = text.trim().replace(/\s+/g, " ");
  if (clean.length <= max) return clean;
  const cut = clean.slice(0, max - 1);
  const space = cut.lastIndexOf(" ");
  return `${space > max / 2 ? cut.slice(0, space) : cut}…`;
}

export function messagePush(
  senderName: string,
  text: string,
  hasImage: boolean,
  fromSecurity: boolean,
): PushContent {
  return {
    title: fromSecurity ? `Security: ${senderName}` : `Message from ${senderName}`,
    body: text.trim() ? preview(text) : hasImage ? "Sent a photo." : "New message.",
  };
}

export function announcementPush(title: string, body: string): PushContent {
  return { title: preview(title, 80), body: preview(body, 200) };
}
