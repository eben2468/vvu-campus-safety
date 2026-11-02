# Decisions — VVU Campus Safety App

Record of choices the proposal left open. Update this file when something changes, and tell Claude Code to read it before assuming.

## Decided

| # | Topic | Decision | Why |
| --- | --- | --- | --- |
| D1 | MVP scope | Build the 4.2 functional requirements + Chapter 1 objectives. Visitor, vehicle, key, patrol and shift-handover modules (Ch3, 4.1) are **Phase 2**. | They aren't in 4.2's requirements; not enough time before December. |
| D2 | ID verification | Seed an `idRoster` collection from a Registry/HR CSV; `verifyId` function checks it at registration. | Makes "student ID authentication" real and testable. |
| D3 | Who gets SOS alerts | All officers with `onDuty == true` (no "nearest officer" routing). | Simpler and reliable on one campus; "nearby" needs constant officer tracking. |
| D4 | Direct communication | In-incident chat + "Call security" button. | Covers Obj ii with no extra infrastructure. |
| D5 | Evidence media | Photos only (max 3, ≤ 1 MB each after compression). No video in MVP. | Storage cost, upload time on mobile data. |
| D6 | Admin dashboard | Flutter Web from the same codebase, hosted on Firebase Hosting. | One language, shared models. |
| D7 | Password security | Firebase Authentication handles password hashing and storage. No custom hashing. | Industry-standard; describe it this way in the thesis. |
| D8 | Roles | Firebase custom claims set only by Cloud Functions. | Clients can't escalate their own role. |
| D9 | Status enum | `new`, `alerted`, `accepted`, `on_scene`, `resolved`, `false_alarm`. Reporter cancel = `resolved` + `cancelledByReporter: true`. | Small, testable state machine. |
| D10 | State management / routing | Riverpod + go_router. | Common, well-documented, testable. |
| D11 | Location tracking | Only during an active SOS; stops when closed. | Privacy and battery. |
| D12 | Project location | The Flutter project lives at the repo root (`campus-security/`), package `gh.edu.vvu.vvu_campus_safety`, created with `--project-name vvu_campus_safety .` | Keeps `CLAUDE.md` and `docs/` beside the code, as the repo layout expects. |
| D13 | Local Firebase project | Develop against the emulator-only project `demo-vvu-campus-safety` (`.firebaserc` default). `lib/firebase_options.dart` holds demo values until `flutterfire configure` replaces it; the real project is the `prod` alias. | The emulators run "demo-" projects with no login or real project, so work can start before the Blaze project exists. |
| D14 | Firebase client config in git | `firebase_options.dart` / `google-services.json` are committed. Service accounts, Maps keys (`android/local.properties`) and the SMS key (Functions secret) are never committed. | Firebase client keys only identify the project; access is enforced by security rules and API key restrictions. |
| D15 | Brand colours | VVU blue `#003A70`, gold `#F2B417`, SOS red `#C62828`; buttons at least 56 dp tall. | Approximate brand colours — swap in official hex values when the brand guide is available. |
| D16 | Rules before M1 | `firestore.rules` and `storage.rules` deny all client access until Milestones 1 and 3. | Safe default; nothing is readable by accident. |
| D17 | Functions test library | `firebase-functions-test` not installed yet: its peer range stops at `firebase-admin` 13 and we use 14. M1 tests the pure `roster.ts` logic with `node:test` and the rules with `@firebase/rules-unit-testing`, or add it when it supports admin 14. | Avoids `--force` installs. |
| D18 | Name check in `verifyId` | The roster surname (last word of `fullName`) must appear among the words the user typed, ignoring case, order and hyphens. The `users` doc stores the roster name, not the typed one. Unknown/inactive IDs are rejected before the name check; "already claimed" only after it. | PRD asks for a case-insensitive surname match; this tolerates first/last name order and reveals less about IDs someone guesses. |
| D19 | Failed registration | The app creates the Auth account, calls `verifyId`, and deletes the account if verification fails. If the delete fails, the user is still signed in but unverified and the router shows a "Verify your VVU ID" screen to retry. `verifyId` is idempotent for the same uid. | Meets "no usable account" without a server-side registration endpoint. |
| D20 | Profile fields users may edit | Rules use an allowlist: `phone` (+233 format) and `fcmTokens`; officers also `onDuty`. Deactivated users can't edit. | Safer than the denylist in the ARCHITECTURE outline — new fields are protected by default. |
| D21 | Role homes and platforms | Mobile: student/staff → `/home`, officer and admin → `/officer`. Web: admin → `/dashboard`, everyone else → "use the mobile app". Self sign-up link hidden on web. | ARCHITECTURE §1: web is admin-only; admins can do everything officers can. |
| D22 | Deactivated users | The app watches `users/{uid}.deactivated`; when true it signs out and shows why on the login screen. Auth `disabled` (set by `adminSetRole`) blocks new sign-ins with the same message. | Covers both a live session and later log-ins. |
| D23 | Push addresses | firebase_messaging 17 deprecates FCM tokens in favour of Firebase Installation IDs (`register()` / `onRegistered`). The app stores the FID in the existing `users.fcmTokens` array; functions send with `sendEachForMulticast({ fids })` and remove IDs FCM reports as stale. Push is mobile-only; the web dashboard uses live Firestore listeners. | Follows the current SDK without renaming a field in the schema. |
| D24 | SOS without GPS | Location is fetched while the countdown runs; after it ends the app waits at most 3 s more, then sends with `location: null` if there is no fix. Live tracking fills `lastLocation` as soon as a fix arrives. | "SOS must never be blocked" — a late location beats a late alert. |
| D25 | Active SOS screen | The member home *becomes* the active SOS screen while the user has an open SOS (one at a time), and location streams for as long as it is shown. Offline is detected from Firestore's `hasPendingWrites`; writes wait at most 6 s for the server, then stay queued. | Simple lifecycle: tracking can't outlive the SOS, and the offline card appears without a connectivity package. |
| D26 | Onboarding | Permissions screen shown once per device after first sign-in on mobile (`shared_preferences`). Declining never blocks; the home screen shows a "location off" card with a fix button. | PRD: handle denial gracefully with a clear explanation. |
| D27 | Timeline events | `onIncidentCreated` writes the `created` and `alerted` events (so offline SOS creation is a single write). Clients may only write events for their own actions: reporters `cancelled`; officers `accepted`, `assigned`, `on_scene`, `note`, `resolved`, `false_alarm`. | Keeps system events trustworthy. |
| D28 | Rules test project | Rules tests use project `demo-vvu-rules-test` and run serially, so they can run against the dev emulators without wiping dev data. | Lets tests run while the app demo is up. |
| D29 | Photo access | Each photo carries custom metadata `reporterId`; `storage.rules` lets that user and officers read it, with no Firestore lookup. `mediaUrls` stores Firebase download URLs, which are only visible to people who can already read the incident. Uploads are create-only (no overwrite or delete), images only, < 2 MB. | ARCHITECTURE §6 offered this option; it keeps Storage rules simple and evidence tamper-proof. |
| D30 | Report submission order | The app picks the incident id, uploads the compressed photos under `incidents/{id}/`, then writes the incident. Photo upload needs a connection (clear error if not); the document write itself queues offline like SOS. | Photos are optional; a report with photos must not point at files that don't exist. |
| D31 | "My reports" | Lists all the user's incidents, SOS alerts included, newest first. Report descriptions must be 10–1000 characters, enforced in the form and in `firestore.rules`. | One place to follow up on anything you raised. |

## Open — need an answer

| # | Topic | Options | Default until decided |
| --- | --- | --- | --- |
| O1 | Visitors | (a) leave out; (b) guest SOS with phone OTP only | (a) leave out — Ch1 restricts to students and staff |
| O2 | SMS gateway for emergency contacts | A Ghana SMS provider with an HTTP API | `ConsoleSmsProvider` logs instead of sending |
| O3 | Security department buy-in | Confirm with the CSO that on-shift officers will carry Android phones with data | Assume yes for the build; test with 2–3 officers |
| O4 | Campus map data | Trace boundary + zones in Google Maps | Use a rough rectangle around Oyibi campus for dev |
| O5 | Security emergency phone number | From the Security Office | Placeholder in seed `settings/app` |
| O6 | Institutional email fallback | If no roster CSV arrives, verify with a university email domain instead | Roster approach (D2) |

## Changelog

- 2026-11-02 — Initial decisions extracted from the proposal and build spec.
- 2026-11-02 — Milestone 0 setup: added D12–D17.
- 2026-11-02 — Milestone 1 auth: added D18–D22.
- 2026-11-02 — Milestone 2 SOS: added D23–D28.
- 2026-11-02 — Milestone 3 reports: added D29–D31.
