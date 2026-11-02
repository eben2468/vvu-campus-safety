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
| D17 | Functions test library | `firebase-functions-test` not installed yet: its peer range stops at `firebase-admin` 13 and we use 14. Test pure logic directly (and through the emulator) in M1, or add it when it supports admin 14. | Avoids `--force` installs. |

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
