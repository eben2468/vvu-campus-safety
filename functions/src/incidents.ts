import { DocumentReference, FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";

import { ApiRequest, documentId, requireCaller } from "./api/request";
import {
  alertedEventText,
  createdEventText,
  IncidentDoc,
  officerAlert,
  reporterUpdate,
  StatusSnapshot,
  statusChangeEffects,
  syncAction,
} from "./incidentLogic";
import { onDutySecurity, pushToUsers, recipientFrom } from "./notifications";
import { getSmsProvider } from "./sms";
import { contactNumbers, Point, sosSmsText } from "./sms/messages";

const SYSTEM_ACTOR = { actorId: "system", actorName: "System" };

/** Most incidents one sweep handles; the next sweep takes the rest. */
const SWEEP_LIMIT = 50;

/**
 * Brings an incident up to date: alerts officers about a new one, or
 * applies the effects of a status change (docs/ARCHITECTURE.md §5).
 *
 * Safe to call any number of times. Each step runs in a transaction that
 * records `handledStatus`, so two calls at once still send one alert.
 */
export async function syncIncident(incidentId: string): Promise<string> {
  const ref = getFirestore().collection("incidents").doc(incidentId);
  const snap = await ref.get();
  const incident = snap.data() as IncidentDoc | undefined;
  if (!incident) return "not-found";

  const action = syncAction(incident);
  if (action === "alert" && (await alertOfficers(ref))) return "alerted";
  // Also reached when the reporter cancelled just before the alert went out.
  if (action !== "none" && (await applyStatusChange(ref))) return "updated";
  return "unchanged";
}

/** The app calls this after every incident write. */
export async function syncIncidentRoute(request: ApiRequest) {
  requireCaller(request);
  return { outcome: await syncIncident(documentId(request.data, "incidentId")) };
}

/**
 * The safety net, run every minute by a scheduler: finishes any incident
 * the app couldn't report, e.g. an SOS that synced after the phone closed
 * the app. Skips incidents at `on_scene`, whose only effect is a courtesy
 * push, so a quiet campus costs a single query per run.
 */
export async function sweepIncidents() {
  const snap = await getFirestore()
    .collection("incidents")
    .where("active", "==", true)
    .where("status", "in", ["new", "accepted", "resolved", "false_alarm"])
    .limit(SWEEP_LIMIT)
    .get();
  const pending = snap.docs.filter((doc) => syncAction(doc.data() as IncidentDoc) !== "none");
  const results = await Promise.allSettled(pending.map((doc) => syncIncident(doc.id)));
  const failed = results.filter((r) => r.status === "rejected").length;
  if (pending.length > 0) console.info("Sweep", { checked: snap.size, synced: pending.length, failed });
  return { checked: snap.size, synced: pending.length - failed, failed };
}

/**
 * New incident: mark it `alerted`, record the `created` and `alerted`
 * events, and push to every on-duty officer. Returns false if another call
 * got there first or the reporter has already cancelled ("I'm safe").
 */
async function alertOfficers(ref: DocumentReference): Promise<boolean> {
  const db = getFirestore();
  const officers = await onDutySecurity();

  const incident = await db.runTransaction(async (tx) => {
    const current = await tx.get(ref);
    const data = current.data() as IncidentDoc | undefined;
    if (!data || data.status !== "new") return null;

    const events = ref.collection("events");
    tx.update(ref, { status: "alerted", handledStatus: "alerted" });
    tx.set(events.doc(), {
      type: "created",
      actorId: data.reporterId,
      actorName: data.reporterName,
      text: createdEventText(data),
      timestamp: current.createTime ?? FieldValue.serverTimestamp(),
    });
    tx.set(events.doc(), {
      type: "alerted",
      ...SYSTEM_ACTOR,
      text: alertedEventText(officers.length),
      timestamp: FieldValue.serverTimestamp(),
    });
    return data;
  });
  if (!incident) return false;

  const sent = await pushToUsers(officers.map(recipientFrom), officerAlert(incident), {
    type: incident.kind,
    incidentId: ref.id,
  });
  console.info("Incident alerted", { incidentId: ref.id, officers: officers.length, pushesSent: sent });

  if (incident.kind === "sos") {
    await textEmergencyContacts(incident, ref.id);
  }
  return true;
}

/**
 * SMS the reporter's emergency contacts with a map link (PRD §4.10).
 * Never throws: a failed SMS must not affect the alert itself.
 */
async function textEmergencyContacts(incident: IncidentDoc & { location?: Point | null }, incidentId: string) {
  try {
    const contacts = await getFirestore().collection("users").doc(incident.reporterId).collection("contacts").get();
    const numbers = contactNumbers(contacts.docs.map((d) => d.data()));
    if (numbers.length === 0) return;
    const text = sosSmsText(incident.reporterName, incident.location);
    const sms = getSmsProvider();
    const results = await Promise.allSettled(numbers.map((to) => sms.send(to, text)));
    const failed = results.filter((r) => r.status === "rejected").length;
    console.info("Emergency contacts texted", { incidentId, sent: numbers.length - failed, failed });
  } catch (error) {
    console.warn("Emergency contact SMS failed", { incidentId, error: String(error) });
  }
}

/**
 * Status change: record `responseSeconds`, close the incident (`active`,
 * `resolvedAt`), count false alarms, and push the update to the reporter.
 * Returns false if there was nothing left to do.
 */
async function applyStatusChange(ref: DocumentReference): Promise<boolean> {
  const db = getFirestore();

  const change = await db.runTransaction(async (tx) => {
    const current = await tx.get(ref);
    const after = current.data() as (IncidentDoc & Record<string, unknown>) | undefined;
    if (!after || syncAction(after) !== "status-change") return null;

    const before = { ...toSnapshot(after), status: after.handledStatus ?? "new" };
    const effects = statusChangeEffects(before, toSnapshot(after));

    const updates: Record<string, unknown> = { handledStatus: after.status };
    if (effects.responseSeconds !== undefined) updates.responseSeconds = effects.responseSeconds;
    if (effects.deactivate) updates.active = false;
    if (effects.setResolvedAt) updates.resolvedAt = FieldValue.serverTimestamp();
    tx.update(ref, updates);
    if (effects.countFalseAlarm) {
      tx.update(db.collection("users").doc(after.reporterId), { falseAlarmCount: FieldValue.increment(1) });
    }
    return { after, notifyReporter: effects.notifyReporter };
  });
  if (!change) return false;
  if (!change.notifyReporter) return true;

  const { after } = change;
  const officerId = after.assignedTo?.[0];
  const officerName = officerId ? (await db.collection("users").doc(officerId).get()).get("fullName") : undefined;
  const content = reporterUpdate(after.status, officerName);
  if (!content) return true;

  const reporter = await db.collection("users").doc(after.reporterId).get();
  await pushToUsers([recipientFrom(reporter)], content, {
    type: "status",
    incidentId: ref.id,
    status: after.status,
  });
  return true;
}

function toSnapshot(doc: IncidentDoc & Record<string, unknown>): StatusSnapshot {
  const date = (value: unknown) => (value instanceof Timestamp ? value.toDate() : undefined);
  return {
    status: doc.status,
    active: doc.active,
    cancelledByReporter: doc.cancelledByReporter,
    createdAt: date(doc.createdAt),
    acknowledgedAt: date(doc.acknowledgedAt),
    resolvedAt: date(doc.resolvedAt),
    responseSeconds: typeof doc.responseSeconds === "number" ? doc.responseSeconds : null,
  };
}
