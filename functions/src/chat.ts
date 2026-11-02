import { getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

import { announcementPush, isAudience, messageAudience, messagePush } from "./chatLogic";
import { IncidentDoc } from "./incidentLogic";
import { onDutySecurity, pushToTopic, pushToUsers, recipientFrom } from "./notifications";

/**
 * New chat message: push it to the other side. A reporter's message goes to
 * the assigned officers (or everyone on duty if nobody is assigned yet);
 * security's message goes to the reporter.
 */
export const onMessageCreated = onDocumentCreated(
  "incidents/{incidentId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message) return;
    const { incidentId } = event.params;
    const db = getFirestore();

    const incident = (await db.collection("incidents").doc(incidentId).get()).data() as IncidentDoc | undefined;
    if (!incident) return;

    const senderId = String(message.senderId ?? "");
    const toSecurity = messageAudience(senderId, incident) === "security";
    let recipients;
    if (!toSecurity) {
      recipients = [await db.collection("users").doc(incident.reporterId).get()];
    } else if (incident.assignedTo?.length) {
      recipients = await db.getAll(...incident.assignedTo.map((uid) => db.collection("users").doc(uid)));
    } else {
      recipients = await onDutySecurity();
    }
    recipients = recipients.filter((user) => user.exists && user.id !== senderId);

    const sent = await pushToUsers(
      recipients.map(recipientFrom),
      messagePush(String(message.senderName ?? ""), String(message.text ?? ""), Boolean(message.imageUrl), !toSecurity),
      { type: "message", incidentId },
    );
    logger.info("Chat message pushed", { incidentId, toSecurity, recipients: recipients.length, sent });
  },
);

/** New announcement: push it to its audience's FCM topic. */
export const onAnnouncementCreated = onDocumentCreated("announcements/{announcementId}", async (event) => {
  const announcement = event.data?.data();
  if (!announcement) return;
  if (!isAudience(announcement.audience)) {
    logger.warn("Announcement with unknown audience", { id: event.params.announcementId });
    return;
  }
  await pushToTopic(
    announcement.audience,
    announcementPush(String(announcement.title ?? ""), String(announcement.body ?? "")),
    { type: "announcement", announcementId: event.params.announcementId },
  );
});
