import { CollectionGroup, CollectionReference, getFirestore } from "firebase-admin/firestore";

import { ApiError } from "./api/errors";
import { BACKUP_MAX_DOCS, BackupDocs, backupPath, encodeValue, sealBackup } from "./backupLogic";
import { getFileStore } from "./photoStore";

const TOP_LEVEL = ["users", "idRoster", "incidents", "announcements", "settings", "auditLogs"];
const NESTED = ["contacts", "events", "messages", "locations"];

/**
 * Daily backup (PRD §4.12): every document, encrypted, saved to the file
 * store. Free-plan Firestore has no managed export, so this reads each
 * document itself. Restore with `npm run restore-backup`.
 */
export async function runBackup() {
  const passphrase = process.env.BACKUP_KEY;
  if (!passphrase) throw new ApiError("failed-precondition", "BACKUP_KEY is not set.");

  const db = getFirestore();
  const sources: (CollectionReference | CollectionGroup)[] = [
    ...TOP_LEVEL.map((name) => db.collection(name)),
    ...NESTED.map((name) => db.collectionGroup(name)),
  ];

  // Counting is cheap; reading too much could lock the app out for the day.
  const counts = await Promise.all(sources.map((source) => source.count().get()));
  const total = counts.reduce((sum, count) => sum + count.data().count, 0);
  if (total > BACKUP_MAX_DOCS) {
    console.error("Backup skipped: database too large for the free plan", { total });
    return { skipped: true, documents: total };
  }

  const docs: BackupDocs = {};
  for (const source of sources) {
    const snap = await source.get();
    for (const doc of snap.docs) docs[doc.ref.path] = encodeValue(doc.data());
  }

  const path = backupPath(new Date());
  const url = await getFileStore().save(path, sealBackup(docs, passphrase), "application/octet-stream");
  console.info("Backup saved", { path, documents: total });
  return { skipped: false, documents: total, url };
}
