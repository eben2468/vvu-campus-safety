/**
 * Loads a sample ID roster, the default `settings/app` document, test
 * admin/officer logins and sample announcements into the local emulators. Run from /functions with
 * the emulators started:
 *
 *   npm run seed
 *
 * Always targets the emulator — it never writes to a real project.
 * Names and IDs are made up; the campus coordinates are a rough placeholder
 * until the real boundary is traced (DECISIONS.md O4).
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, GeoPoint, getFirestore } from "firebase-admin/firestore";

process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";
const PROJECT_ID = "demo-vvu-campus-safety";

const roster = [
  { idNumber: "223IT0100001", fullName: "Kwame Mensah", type: "student", department: "Information Technology", active: true },
  { idNumber: "223IT0100002", fullName: "Yaw Darko", type: "student", department: "Information Technology", active: true },
  { idNumber: "222NU0200015", fullName: "Abena Owusu", type: "student", department: "Nursing", active: true },
  { idNumber: "224BA0300042", fullName: "Kofi Asante", type: "student", department: "Business Administration", active: true },
  { idNumber: "221TH0400007", fullName: "Akosua Boateng", type: "student", department: "Theology", active: true },
  { idNumber: "219IT0100088", fullName: "Ama Sarpong", type: "student", department: "Information Technology", active: false },
  { idNumber: "STF00012", fullName: "Efua Addo", type: "staff", department: "Registry", active: true },
  { idNumber: "STF00031", fullName: "Kwesi Appiah", type: "staff", department: "Information Technology", active: true },
];

// Rough centre of VVU Oyibi campus; zones are offsets around it.
const centre = { lat: 5.793, lng: -0.122 };
const point = (dLat: number, dLng: number) => new GeoPoint(centre.lat + dLat, centre.lng + dLng);

const settings = {
  categories: ["Theft", "Assault", "Harassment", "Medical", "Fire", "Accident", "Suspicious activity", "Other"],
  securityPhone: "+233000000000", // placeholder until the Security Office number is known (O5)
  sosCountdownSec: 3,
  campusBoundary: [point(0.004, -0.004), point(0.004, 0.004), point(-0.004, 0.004), point(-0.004, -0.004)],
  zones: [
    { name: "Main gate", center: point(-0.0035, 0), radiusM: 60 },
    { name: "Hostels", center: point(0.002, -0.002), radiusM: 150 },
    { name: "Lecture halls", center: point(0, 0.001), radiusM: 120 },
    { name: "Admin block", center: point(-0.001, -0.001), radiusM: 80 },
    { name: "Church", center: point(0.001, 0.0025), radiusM: 80 },
    { name: "Sports field", center: point(0.003, 0.003), radiusM: 120 },
  ],
};

// Emulator-only test logins (officers and admins are never self-registered).
const PASSWORD = "password123";
const staffAccounts = [
  { email: "admin@vvu.test", fullName: "Test Admin", role: "admin", phone: "+233200000001" },
  { email: "officer@vvu.test", fullName: "Test Officer", role: "officer", phone: "+233200000002" },
];

/** Creates (or updates) an emulator Auth user with claims and a users doc. */
async function seedStaffAccount(account: (typeof staffAccounts)[number]): Promise<string> {
  const auth = getAuth();
  const user = await auth.getUserByEmail(account.email).catch(() =>
    auth.createUser({ email: account.email, password: PASSWORD, emailVerified: true, displayName: account.fullName }),
  );
  await auth.setCustomUserClaims(user.uid, { role: account.role, verified: true });
  await getFirestore().collection("users").doc(user.uid).set({
    fullName: account.fullName,
    idNumber: null,
    email: account.email,
    phone: account.phone,
    role: account.role,
    verified: true,
    onDuty: false,
    fcmTokens: [],
    falseAlarmCount: 0,
    deactivated: false,
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return user.uid;
}

// Fixed ids, so re-seeding doesn't duplicate them.
const announcements = [
  {
    id: "welcome",
    title: "Welcome to VVU Campus Safety",
    body: "Press SOS in any emergency and security will see where you are. Use Report for non-urgent incidents.",
    audience: "all",
  },
  {
    id: "night-escort",
    title: "Night escort service",
    body: "After 10 pm, security officers can walk you from the library to the hostels. Call the Security Office to book.",
    audience: "students",
  },
];

async function main(): Promise<void> {
  initializeApp({ projectId: PROJECT_ID });
  const db = getFirestore();
  const batch = db.batch();

  for (const entry of roster) {
    // merge keeps `claimedBy` on IDs that were already registered.
    batch.set(
      db.collection("idRoster").doc(entry.idNumber),
      { ...entry, importedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  }
  batch.set(db.collection("settings").doc("app"), settings);

  await batch.commit();
  const uids: string[] = [];
  for (const account of staffAccounts) {
    uids.push(await seedStaffAccount(account));
  }
  for (const { id, ...announcement } of announcements) {
    const ref = db.collection("announcements").doc(id);
    if (!(await ref.get()).exists) {
      await ref.set({ ...announcement, createdBy: uids[0], createdAt: FieldValue.serverTimestamp() });
    }
  }
  console.log(`Seeded ${roster.length} roster entries and settings/app into ${process.env.FIRESTORE_EMULATOR_HOST}.`);
  console.log(`Test logins (password ${PASSWORD}): ${staffAccounts.map((a) => `${a.email} (${a.role})`).join(", ")}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
