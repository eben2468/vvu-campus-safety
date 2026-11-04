import { DocumentSnapshot, FieldValue, getFirestore, QueryDocumentSnapshot } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

import { PushContent } from "./incidentLogic";

/** A user and their devices' push IDs (`users/{uid}.fcmTokens`). */
export interface Recipient {
  uid: string;
  pushIds: string[];
}

// FCM errors meaning the push ID will never work again.
const STALE_ID_ERRORS = ["messaging/registration-token-not-registered", "messaging/invalid-registration-token"];

export function recipientFrom(user: DocumentSnapshot): Recipient {
  const ids = user.get("fcmTokens");
  return { uid: user.id, pushIds: Array.isArray(ids) ? ids.filter((id) => typeof id === "string") : [] };
}

/**
 * Sends a high-priority push on the `sos_alerts` channel to every device of
 * every recipient, and removes push IDs FCM reports as stale. Never throws:
 * a failed push must not undo the status change that triggered it.
 * Returns how many devices accepted the message.
 */
export async function pushToUsers(
  recipients: Recipient[],
  content: PushContent,
  data: Record<string, string>,
): Promise<number> {
  const targets = recipients.flatMap((r) => r.pushIds.map((pushId) => ({ uid: r.uid, pushId })));
  if (targets.length === 0) return 0;

  try {
    const response = await getMessaging().sendEachForMulticast({
      fids: targets.map((t) => t.pushId),
      notification: content,
      data,
      android: { priority: "high", notification: { channelId: "sos_alerts", sound: "default" } },
    });
    const stale = targets.filter((_, i) => {
      const error = response.responses[i]?.error;
      return error !== undefined && STALE_ID_ERRORS.includes(error.code);
    });
    await Promise.all(
      stale.map((t) =>
        getFirestore().collection("users").doc(t.uid).update({ fcmTokens: FieldValue.arrayRemove(t.pushId) }),
      ),
    );
    return response.successCount;
  } catch (error) {
    // Expected on the emulator: FCM is not emulated.
    console.warn("Push failed", { error: String(error) });
    return 0;
  }
}

/** Officers and admins who are on duty — the people who get new alerts. */
export async function onDutySecurity(): Promise<QueryDocumentSnapshot[]> {
  const snap = await getFirestore()
    .collection("users")
    .where("role", "in", ["officer", "admin"])
    .where("onDuty", "==", true)
    .get();
  return snap.docs;
}

/**
 * Sends to an FCM topic (`all`, `students`, `staff`, `officers`), which
 * each device subscribes to at sign-in. Never throws.
 */
export async function pushToTopic(topic: string, content: PushContent, data: Record<string, string>): Promise<boolean> {
  try {
    await getMessaging().send({
      topic,
      notification: content,
      data,
      android: { priority: "high", notification: { channelId: "announcements" } },
    });
    return true;
  } catch (error) {
    console.warn("Topic push failed", { topic, error: String(error) });
    return false;
  }
}
