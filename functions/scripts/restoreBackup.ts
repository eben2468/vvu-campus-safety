/**
 * Restores a backup made by `runBackup` (docs/SETUP.md §8).
 *
 *   $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\keys\service-account.json"
 *   $env:BACKUP_KEY = "<the passphrase set on Vercel>"
 *   npm run restore-backup -- <project-id> <backup file>
 *
 * Writes every document in the file over what is there now. Documents added
 * since the backup are left alone.
 */
import { readFile } from "node:fs/promises";

import { applicationDefault, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

import { decodeValue, openBackup } from "../src/backupLogic";

async function main(): Promise<void> {
  const [projectId, file] = process.argv.slice(2);
  const passphrase = process.env.BACKUP_KEY;
  if (!projectId || !file || !passphrase) {
    throw new Error("Usage: set BACKUP_KEY, then npm run restore-backup -- <project-id> <backup file>");
  }
  const docs = openBackup(await readFile(file), passphrase);

  initializeApp({ credential: applicationDefault(), projectId });
  const db = getFirestore();
  const writer = db.bulkWriter();
  for (const [path, data] of Object.entries(docs)) {
    void writer.set(db.doc(path), decodeValue(data) as Record<string, unknown>);
  }
  await writer.close();
  console.log(`Restored ${Object.keys(docs).length} documents to ${projectId}.`);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
