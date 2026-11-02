import { v1 } from "@google-cloud/firestore";
import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { backupUri, defaultBucket } from "./backupLogic";

/**
 * Daily Firestore export to Cloud Storage (PRD §4.12) at 02:00 Accra time.
 * The Functions service account needs the "Cloud Datastore Import Export
 * Admin" role and write access to the bucket (docs/SETUP.md). Scheduled
 * functions don't run in the emulator.
 */
export const scheduledBackup = onSchedule(
  { schedule: "0 2 * * *", timeZone: "Africa/Accra", retryCount: 2 },
  async () => {
    const projectId = process.env.GCLOUD_PROJECT;
    const bucket = defaultBucket(process.env.FIREBASE_CONFIG);
    if (!projectId || !bucket) throw new Error("Project id or storage bucket not configured.");

    const client = new v1.FirestoreAdminClient();
    const outputUriPrefix = backupUri(bucket, new Date());
    const [operation] = await client.exportDocuments({
      name: client.databasePath(projectId, "(default)"),
      outputUriPrefix,
      collectionIds: [], // every collection
    });
    logger.info("Firestore backup started", { outputUriPrefix, operation: operation.name });
  },
);
