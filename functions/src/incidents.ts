import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";

import {
  alertedEventText,
  createdEventText,
  IncidentDoc,
  officerAlert,
  reporterUpdate,
  StatusSnapshot,
  statusChangeEffects,
} from "./incidentLogic";
import { onDutySecurity, pushToUsers, recipientFrom } from "./notifications";

const SYSTEM_ACTOR = { actorId: "system", actorName: "System" };

/**
 * New incident (docs/ARCHITECTURE.md §5): mark it `alerted`, record the
 * `created` and `alerted` events, and push to every on-duty officer.
 */
export const onIncidentCreated = onDocumentCreated("incidents/{incidentId}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const db = getFirestore();

  const officers = await onDutySecurity();

  // In a transaction: the reporter may already have cancelled ("I'm safe").
  const incident = await db.runTransaction(async (tx) => {
    const current = await tx.get(snap.ref);
    const data = current.data() as IncidentDoc | undefined;
    if (!data || data.status !== "new") return null;

    const events = snap.ref.collection("events");
    tx.update(snap.ref, { status: "alerted" });
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
  if (!incident) return;

  const sent = await pushToUsers(officers.map(recipientFrom), officerAlert(incident), {
    type: incident.kind,
    incidentId: event.params.incidentId,
  });
  logger.info("Incident alerted", { incidentId: event.params.incidentId, officers: officers.length, pushesSent: sent });
});

/**
 * Status change: record `responseSeconds`, close the incident (`active`,
 * `resolvedAt`), count false alarms, and push the update to the reporter.
 */
export const onIncidentUpdated = onDocumentUpdated("incidents/{incidentId}", async (event) => {
  const change = event.data;
  if (!change) return;
  const before = change.before.data() as IncidentDoc & Record<string, unknown>;
  const after = change.after.data() as IncidentDoc & Record<string, unknown>;
  if (before.status === after.status) return; // also stops this trigger re-running on its own writes

  const db = getFirestore();
  const effects = statusChangeEffects(toSnapshot(before), toSnapshot(after));

  const updates: Record<string, unknown> = {};
  if (effects.responseSeconds !== undefined) updates.responseSeconds = effects.responseSeconds;
  if (effects.deactivate) updates.active = false;
  if (effects.setResolvedAt) updates.resolvedAt = FieldValue.serverTimestamp();
  if (Object.keys(updates).length > 0) await change.after.ref.update(updates);

  if (effects.countFalseAlarm) {
    await db.collection("users").doc(after.reporterId).update({ falseAlarmCount: FieldValue.increment(1) });
  }

  if (!effects.notifyReporter) return;
  const officerId = after.assignedTo?.[0];
  const officerName = officerId ? (await db.collection("users").doc(officerId).get()).get("fullName") : undefined;
  const content = reporterUpdate(after.status, officerName);
  if (!content) return;

  const reporter = await db.collection("users").doc(after.reporterId).get();
  await pushToUsers([recipientFrom(reporter)], content, {
    type: "status",
    incidentId: event.params.incidentId,
    status: after.status,
  });
});

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
