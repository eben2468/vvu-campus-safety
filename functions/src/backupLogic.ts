/**
 * Where the daily Firestore export goes. Pure; unit tested in
 * test/unit/backupLogic.test.ts.
 */

/** `gs://<bucket>/backups/YYYY-MM-DD`, dated in Africa/Accra (UTC). */
export function backupUri(bucket: string, date: Date): string {
  return `gs://${bucket}/backups/${date.toISOString().slice(0, 10)}`;
}

/** The project's default Storage bucket from FIREBASE_CONFIG, if set. */
export function defaultBucket(firebaseConfig: string | undefined): string | undefined {
  if (!firebaseConfig) return undefined;
  try {
    const bucket = (JSON.parse(firebaseConfig) as { storageBucket?: unknown }).storageBucket;
    return typeof bucket === "string" && bucket.length > 0 ? bucket : undefined;
  } catch {
    return undefined;
  }
}
