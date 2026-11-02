/**
 * Creates the first admin on the real project (docs/SETUP.md §7). After
 * that, admins create officers and other admins from the dashboard.
 *
 *   gcloud auth application-default login
 *   npm run make-admin -- <project-id> <email> "<Full Name>" <+233 phone> <temporary password>
 *
 * Uses Application Default Credentials; nothing secret is stored in the
 * repo. If the email already has an account, it is promoted instead and
 * the password argument is ignored.
 */
import { applicationDefault, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

import { parseCreateUserInput } from "../src/adminLogic";

async function main(): Promise<void> {
  const [projectId, email, fullName, phone, password] = process.argv.slice(2);
  if (!projectId || !email || !fullName || !phone) {
    throw new Error("Usage: npm run make-admin -- <project-id> <email> \"<Full Name>\" <+233 phone> <temporary password>");
  }
  const parsed = parseCreateUserInput({ email, password: password ?? "unused-placeholder", fullName, phone, role: "admin" });
  if (!parsed.ok) throw new Error(parsed.message);
  const input = parsed.value;

  initializeApp({ credential: applicationDefault(), projectId });
  const auth = getAuth();
  const existing = await auth.getUserByEmail(input.email).catch(() => null);
  if (!existing && !password) throw new Error("No account for this email yet: give a temporary password.");
  const user = existing ?? (await auth.createUser({
    email: input.email,
    password: input.password,
    displayName: input.fullName,
    emailVerified: true,
  }));

  await auth.setCustomUserClaims(user.uid, { role: "admin", verified: true });
  await getFirestore().collection("users").doc(user.uid).set({
    fullName: input.fullName,
    idNumber: null,
    email: input.email,
    phone: input.phone,
    role: "admin",
    verified: true,
    onDuty: false,
    fcmTokens: [],
    falseAlarmCount: 0,
    deactivated: false,
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  console.log(`${input.email} is now an admin on ${projectId}${existing ? " (existing account)" : ""}.`);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
