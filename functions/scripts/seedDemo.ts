/**
 * Loads realistic past incidents into the local emulators for the
 * analytics demo and thesis screenshots (BUILD_PLAN Milestone 7):
 * 120 incidents over the last 12 weeks, clustered in the campus zones,
 * each with a full timeline. Run from /functions after `npm run seed`,
 * with the emulators started:
 *
 *   npm run seed:demo
 *
 * Always targets the emulator. Incident ids start with `demo-` and the
 * random numbers are seeded, so running it again rewrites the same data.
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { GeoPoint, getFirestore, Timestamp, WriteBatch } from "firebase-admin/firestore";

process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";
const PROJECT_ID = "demo-vvu-campus-safety";
const COUNT = 120;
const WEEKS = 12;

/** Small seeded random generator (mulberry32), so every run is the same. */
function random(seed: number): () => number {
  return () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const rand = random(2026);
const pick = <T>(items: T[]): T => items[Math.floor(rand() * items.length)];
const between = (min: number, max: number) => min + rand() * (max - min);

// Matches the zones in seedRoster.ts. Each has the incidents typical there
// and the hours they usually happen.
const centre = { lat: 5.793, lng: -0.122 };
const zones = [
  { name: "Hostels", lat: 0.002, lng: -0.002, radiusM: 150, weight: 5, categories: ["Theft", "Harassment", "Medical", "Suspicious activity"], hours: [19, 2] },
  { name: "Lecture halls", lat: 0, lng: 0.001, radiusM: 120, weight: 3, categories: ["Theft", "Medical", "Other"], hours: [8, 18] },
  { name: "Main gate", lat: -0.0035, lng: 0, radiusM: 60, weight: 2, categories: ["Suspicious activity", "Accident", "Assault"], hours: [17, 23] },
  { name: "Sports field", lat: 0.003, lng: 0.003, radiusM: 120, weight: 2, categories: ["Accident", "Medical", "Theft"], hours: [15, 20] },
  { name: "Admin block", lat: -0.001, lng: -0.001, radiusM: 80, weight: 1, categories: ["Theft", "Other"], hours: [8, 17] },
  { name: "Church", lat: 0.001, lng: 0.0025, radiusM: 80, weight: 1, categories: ["Theft", "Medical", "Fire"], hours: [6, 21] },
];

const descriptions: Record<string, string[]> = {
  "Theft": ["My phone was taken from my desk while I stepped out.", "Someone took my laptop bag from the reading room.", "My bicycle was stolen from outside the block."],
  "Harassment": ["A man keeps following me and calling out at night.", "Someone has been sending threats and waiting outside my room."],
  "Medical": ["A student fainted and is not responding well.", "My room mate has a high fever and can't stand up."],
  "Suspicious activity": ["Two people without IDs are checking door handles.", "A car has been parked with its lights off for an hour."],
  "Accident": ["A motorbike knocked down a student near the gate.", "Someone fell during the match and hurt their leg badly."],
  "Assault": ["Two students are fighting and one is bleeding."],
  "Fire": ["Smoke is coming from the kitchen area."],
  "Other": ["A water pipe burst and the corridor is flooding.", "The street light is out and the path is completely dark."],
};

const reporters = [
  "Kwame Mensah", "Abena Owusu", "Kofi Asante", "Akosua Boateng", "Yaw Darko", "Esi Quaye",
  "Nana Ofori", "Efua Addo", "Kwesi Appiah", "Adwoa Sarpong", "Kojo Nyarko", "Afia Mensah",
].map((name, i) => ({ uid: `demo-reporter-${i + 1}`, name, phone: `+23324000${String(1000 + i).slice(-4)}` }));

/** A point inside [zone], uniformly over its circle. */
function pointIn(zone: (typeof zones)[number]): GeoPoint {
  const metres = zone.radiusM * Math.sqrt(rand());
  const angle = rand() * 2 * Math.PI;
  const dLat = (metres * Math.cos(angle)) / 111320;
  const dLng = (metres * Math.sin(angle)) / (111320 * Math.cos((centre.lat * Math.PI) / 180));
  return new GeoPoint(centre.lat + zone.lat + dLat, centre.lng + zone.lng + dLng);
}

/** A time in the last [WEEKS] weeks at an hour typical for the zone (UTC = Accra). */
function timeFor(zone: (typeof zones)[number], now: Date): Date {
  const [from, to] = zone.hours;
  const span = (to - from + 24) % 24 || 24;
  const daysAgo = Math.floor(rand() * WEEKS * 7) + 1;
  const day = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - daysAgo));
  return new Date(day.getTime() + ((from + rand() * span) % 24) * 3600_000);
}

const weighted = zones.flatMap((z) => Array<typeof z>(z.weight).fill(z));

async function main(): Promise<void> {
  initializeApp({ projectId: PROJECT_ID });
  const db = getFirestore();
  const officer = await getAuth().getUserByEmail("officer@vvu.test").catch(() => null);
  const officerId = officer?.uid ?? "demo-officer";
  const officerName = "Test Officer";

  const now = new Date();
  let batch: WriteBatch = db.batch();
  let writes = 0;
  const write = async (fn: (b: WriteBatch) => void) => {
    fn(batch);
    if (++writes % 400 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  };

  for (let n = 1; n <= COUNT; n++) {
    const zone = pick(weighted);
    const sos = rand() < 0.2;
    const category = sos ? "emergency" : pick(zone.categories);
    const reporter = pick(reporters);
    const location = pointIn(zone);
    const createdAt = timeFor(zone, now);
    // SOS alerts are picked up faster than written reports.
    const responseSeconds = Math.round(sos ? between(25, 240) : between(90, 1500));
    const roll = rand();
    const outcome = roll < 0.08 ? "false_alarm" : sos && roll < 0.14 ? "cancelled" : "resolved";
    const acknowledgedAt = new Date(createdAt.getTime() + responseSeconds * 1000);
    const onSceneAt = new Date(acknowledgedAt.getTime() + between(120, 600) * 1000);
    const resolvedAt = outcome === "cancelled"
      ? new Date(createdAt.getTime() + between(20, 60) * 1000)
      : new Date(onSceneAt.getTime() + between(300, 2400) * 1000);

    const id = `demo-${String(n).padStart(3, "0")}`;
    const ref = db.collection("incidents").doc(id);
    const accepted = outcome !== "cancelled";
    await write((b) => b.set(ref, {
      kind: sos ? "sos" : "report",
      category,
      description: sos ? "" : pick(descriptions[category] ?? descriptions.Other),
      status: outcome === "false_alarm" ? "false_alarm" : "resolved",
      reporterId: reporter.uid,
      reporterName: reporter.name,
      reporterPhone: reporter.phone,
      location,
      geohash: "",
      lastLocation: location,
      locationLabel: zone.name,
      mediaUrls: [],
      assignedTo: accepted ? [officerId] : [],
      createdAt: Timestamp.fromDate(createdAt),
      acknowledgedAt: accepted ? Timestamp.fromDate(acknowledgedAt) : null,
      resolvedAt: Timestamp.fromDate(resolvedAt),
      responseSeconds: accepted ? responseSeconds : null,
      active: false,
      cancelledByReporter: outcome === "cancelled",
    }));

    const events: [string, string, string, string, Date][] = [
      ["created", reporter.uid, reporter.name, sos ? `${reporter.name} pressed SOS.` : `${reporter.name} reported: ${category}.`, createdAt],
      ["alerted", "system", "System", "Sent to 3 on-duty officers.", new Date(createdAt.getTime() + 2000)],
    ];
    if (outcome === "cancelled") {
      events.push(["cancelled", reporter.uid, reporter.name, `${reporter.name} marked themselves safe.`, resolvedAt]);
    } else {
      events.push(["accepted", officerId, officerName, `${officerName} accepted the alert.`, acknowledgedAt]);
      events.push(["on_scene", officerId, officerName, `${officerName} arrived on scene.`, onSceneAt]);
      events.push(outcome === "false_alarm"
        ? ["false_alarm", officerId, officerName, `${officerName} marked this as a false alarm.`, resolvedAt]
        : ["resolved", officerId, officerName, `${officerName} resolved the incident.`, resolvedAt]);
    }
    for (const [i, [type, actorId, actorName, text, at]] of events.entries()) {
      await write((b) => b.set(ref.collection("events").doc(`e${i}`), { type, actorId, actorName, text, timestamp: Timestamp.fromDate(at) }));
    }
  }
  await batch.commit();
  console.log(`Seeded ${COUNT} past incidents (ids demo-001…demo-${COUNT}) over ${WEEKS} weeks into ${process.env.FIRESTORE_EMULATOR_HOST}.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
