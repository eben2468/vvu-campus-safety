import { DocumentData, DocumentReference, FieldValue, getFirestore } from "firebase-admin/firestore";

import { ApiError } from "./api/errors";
import { ApiRequest, documentId, requireAdmin, requireCaller } from "./api/request";
import { announcementPush, isAudience, messageAudience, messagePush } from "./chatLogic";
import { IncidentDoc } from "./incidentLogic";
import { onDutySecurity, pushToTopic, pushToUsers, recipientFrom } from "./notifications";

/**
 * Marks a document as pushed and returns its data, or null if it was pushed
 * already, so a repeated call never sends a second notification.
 */
async function claimPush(ref: DocumentReference): Promise<DocumentData | null> {
  return getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data();
    if (!data) throw new ApiError("not-found", "This item no longer exists.");
    if (data.pushedAt) return null;
    tx.update(ref, { pushedAt: FieldValue.serverTimestamp() });
    return data;
  });
}

/**
 * The app calls this after sending a chat message, to push it to the other
 * side. A reporter's message goes to the assigned officers (or everyone on
 * duty if nobody is assigned yet); security's message goes to the reporter.
 */
export async function notifyMessage(request: ApiRequest) {
  const caller = requireCaller(request);
  const incidentId = documentId(request.data, "incidentId");
  const messageId = documentId(request.data, "messageId");
  const db = getFirestore();
  const incidentRef = db.collection("incidents").doc(incidentId);
  const messageRef = incidentRef.collection("messages").doc(messageId);

  // Only the sender can trigger the push for their own message.
  const sender = (await messageRef.get()).get("senderId");
  if (sender !== caller.uid) throw new ApiError("permission-denied", "Not your message.");

  const message = await claimPush(messageRef);
  if (!message) return { sent: 0 };
  const incident = (await incidentRef.get()).data() as IncidentDoc | undefined;
  if (!incident) return { sent: 0 };

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
  console.info("Chat message pushed", { incidentId, toSecurity, recipients: recipients.length, sent });
  return { sent };
}

/** The dashboard calls this after posting, to push to the audience's FCM topic. */
export async function notifyAnnouncement(request: ApiRequest) {
  requireAdmin(request);
  const announcementId = documentId(request.data, "announcementId");
  const announcement = await claimPush(getFirestore().collection("announcements").doc(announcementId));
  if (!announcement) return { sent: false };
  if (!isAudience(announcement.audience)) {
    console.warn("Announcement with unknown audience", { announcementId });
    return { sent: false };
  }
  const sent = await pushToTopic(
    announcement.audience,
    announcementPush(String(announcement.title ?? ""), String(announcement.body ?? "")),
    { type: "announcement", announcementId },
  );
  return { sent };
}
