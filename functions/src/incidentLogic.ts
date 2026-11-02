/**
 * Decisions the incident triggers make. Pure functions with no Firebase
 * imports, so they can be unit tested (test/unit/incidentLogic.test.ts).
 */

/** The fixed status enum (CLAUDE.md, docs/ARCHITECTURE.md §4). */
export type IncidentStatus = "new" | "alerted" | "accepted" | "on_scene" | "resolved" | "false_alarm";

/** The fields of an `incidents/{id}` document the triggers use. */
export interface IncidentDoc {
  kind: "sos" | "report";
  category: string;
  status: IncidentStatus;
  reporterId: string;
  reporterName: string;
  locationLabel?: string | null;
  assignedTo?: string[];
  active?: boolean;
  cancelledByReporter?: boolean;
}

/** Status plus the timestamps, already converted to Dates. */
export interface StatusSnapshot {
  status: IncidentStatus;
  active?: boolean;
  cancelledByReporter?: boolean;
  createdAt?: Date;
  acknowledgedAt?: Date;
  resolvedAt?: Date;
  responseSeconds?: number | null;
}

export interface PushContent {
  title: string;
  body: string;
}

export function isClosed(status: IncidentStatus): boolean {
  return status === "resolved" || status === "false_alarm";
}

/** Text of the `created` event the trigger records. */
export function createdEventText(incident: IncidentDoc): string {
  return incident.kind === "sos"
    ? `${incident.reporterName} pressed SOS.`
    : `${incident.reporterName} reported: ${incident.category}.`;
}

/** Text of the `alerted` event, saying how many officers were notified. */
export function alertedEventText(officerCount: number): string {
  if (officerCount === 0) {
    return "No officers are on duty. The alert is waiting on the dashboard.";
  }
  return `Sent to ${officerCount} on-duty officer${officerCount === 1 ? "" : "s"}.`;
}

/** Push shown to on-duty officers for a new incident. */
export function officerAlert(incident: IncidentDoc): PushContent {
  const where = incident.locationLabel ? ` near ${incident.locationLabel}` : "";
  return incident.kind === "sos"
    ? { title: `SOS — ${incident.reporterName}`, body: `Emergency${where}. Tap to see their live location.` }
    : { title: `New report: ${incident.category}`, body: `From ${incident.reporterName}${where}.` };
}

/** Push shown to the reporter when their incident's status changes, if any. */
export function reporterUpdate(status: IncidentStatus, officerName?: string): PushContent | null {
  const officer = officerName ?? "An officer";
  switch (status) {
    case "accepted":
      return { title: "Help is on the way", body: `${officer} accepted your alert and is coming.` };
    case "on_scene":
      return { title: "Officer has arrived", body: `${officer} is at your location.` };
    case "resolved":
      return { title: "Incident resolved", body: "Security has closed your incident. Stay safe." };
    case "false_alarm":
      return {
        title: "Closed as a false alarm",
        body: "Security closed your alert as a false alarm. Contact them if this is wrong.",
      };
    default:
      return null;
  }
}

export interface StatusChangeEffects {
  /** Seconds from creation to first accept; set once. */
  responseSeconds?: number;
  /** Closed incidents get `active: false` (simplifies queries). */
  deactivate: boolean;
  setResolvedAt: boolean;
  /** Counts against the reporter's `falseAlarmCount`. */
  countFalseAlarm: boolean;
  /** The reporter isn't told about a change they made themselves. */
  notifyReporter: boolean;
}

/** What `onIncidentUpdated` should do after a status change. */
export function statusChangeEffects(before: StatusSnapshot, after: StatusSnapshot): StatusChangeEffects {
  const closed = isClosed(after.status);
  let responseSeconds: number | undefined;
  if (after.acknowledgedAt && after.createdAt && after.responseSeconds == null) {
    responseSeconds = Math.max(0, Math.round((after.acknowledgedAt.getTime() - after.createdAt.getTime()) / 1000));
  }
  return {
    responseSeconds,
    deactivate: closed && after.active !== false,
    setResolvedAt: closed && !after.resolvedAt,
    countFalseAlarm: after.status === "false_alarm" && before.status !== "false_alarm",
    notifyReporter: after.cancelledByReporter !== true,
  };
}
