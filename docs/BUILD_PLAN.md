# Build Plan — VVU Campus Safety App

Eight weeks to a demo-ready MVP for Project 2 (due December). Work top to bottom; tick boxes as you go. Each milestone ends with something you can demo.

Tip for Claude Code: start a session with *"Read CLAUDE.md and docs/BUILD_PLAN.md, then do the next unchecked task in Milestone N. Follow the acceptance criteria in docs/PRD.md."*

## Milestone 0 — Project setup (Day 1–2)

- [ ] Follow `docs/SETUP.md` (Flutter, Firebase CLI, FlutterFire CLI, Node, emulators) — tools installed; still to do by hand: Android cmdline-tools + `flutter doctor --android-licenses`
- [x] `flutter create --org gh.edu.vvu --platforms=android,web vvu_campus_safety`
- [x] Add packages listed in `CLAUDE.md`
- [x] `flutterfire configure` → `firebase_options.dart`; `firebase_options_demo.dart` is used with the emulators (D13)
- [x] `firebase init` (Firestore, Functions TypeScript, Storage, Hosting, Emulators) — config written by hand for the demo project; rules deny all for now (D16)
- [x] Create folder layout from `ARCHITECTURE.md` §9 with empty placeholder files
- [x] Theme (VVU colours, large touch targets), `core/constants.dart` with collection names and enums
- [x] `USE_EMULATOR` dart-define wiring in `main.dart`
- [x] Git repo + `.gitignore` (exclude keys, `local.properties`, service accounts)

**Demo:** app runs on Android and Chrome against the emulators.

## Milestone 1 — Auth and ID verification (Week 1)

- [x] Models: `AppUser`, `IncidentStatus` enum
- [x] `verifyId` callable function + unit test
- [x] Seed script: `functions/scripts/seedRoster.ts` loads sample `idRoster` and `settings/app` into the emulator
- [x] Register screen → calls `verifyId`; success/failure states
- [x] Login, forgot password, logout; email verification banner
- [x] Router redirects by auth state + `role` claim (student/staff → home, officer → officer home, admin on web → dashboard)
- [x] Deactivated user handling
- [x] First version of `firestore.rules` for `users` and `idRoster` + rules tests

**Demo:** a seeded student ID registers and lands on home; a fake ID is rejected.

## Milestone 2 — SOS end to end (Weeks 2–3)

- [x] Onboarding permission screens (location, notifications)
- [x] Home screen with SOS button + countdown/cancel
- [x] `IncidentRepository.createSos()` with current location
- [x] `onIncidentCreated` function: status → `alerted`, event, FCM to on-duty officers
- [x] FCM setup: token storage, topics, foreground local notifications, tap routing
- [x] Active SOS screen; location streaming to `locations` + `lastLocation`; foreground service notification
- [x] "I'm safe" cancel
- [x] Offline fallback: queued write + SMS/call to `securityPhone`
- [x] Officer home: on-duty toggle + live queue
- [x] Alert detail: live map of reporter, Navigate button, Accept
- [x] `onIncidentUpdated`: `responseSeconds`, reporter push
- [x] Rules for `incidents` + `locations` + tests

**Demo:** student phone hits SOS → officer phone rings within seconds → officer sees moving dot and accepts → student sees "Officer X is on the way".

## Milestone 3 — Incident reporting (Week 4)

- [x] Report form: category, description, up to 3 photos (compress), map pin
- [x] Upload to Storage + `storage.rules`
- [x] My reports list with status chips
- [x] Incident detail with photos, map and `events` timeline

**Demo:** report a "Theft" with two photos; officer receives it and sees the photos.

## Milestone 4 — Response workflow, chat, announcements (Week 5)

- [x] Officer actions: assign, on scene, add note, resolve, false alarm (with transition checks)
- [x] Per-incident chat (text + optional photo) for reporter and officers
- [x] `onMessageCreated` push
- [x] Call security button
- [x] Announcements list in app; `onAnnouncementCreated` topic push

**Demo:** full lifecycle new → resolved with chat on both phones.

## Milestone 5 — Admin web dashboard (Week 6)

- [x] Admin shell (side nav) for web
- [x] Live board: campus map + active incident list, new-SOS sound/flash, summary cards
- [x] Incidents page: filterable table + detail drawer with all actions
- [x] Users page: search, create officer/admin (`adminCreateUser`), change role / deactivate (`adminSetRole`)
- [x] Roster CSV import (`adminImportRoster`) and a list of imported IDs
- [x] Announcements composer
- [x] Deploy dashboard to Firebase Hosting (free Spark plan, D52); `firebase.json` hosting serves `build/web`

**Demo:** CSO watches the live board while a test SOS comes in and is resolved.

## Milestone 6 — Analytics and extras (Week 7)

- [x] Heatmap of incidents with date-range + category filters
- [x] Charts: per category, per week, response-time trend (`fl_chart`)
- [x] CSV export of filtered incidents
- [x] Emergency contacts CRUD + SMS on SOS (via `SmsProvider`)
- [x] Settings page (categories, phone, countdown, boundary/zones)
- [x] Audit log page
- [x] `scheduledBackup` function (runs only once deployed; IAM step in SETUP §8)

**Demo:** heatmap shows clusters from seeded historical incidents.

## Milestone 7 — Testing, polish, documentation (Week 8)

- [x] Seed realistic demo data (≥ 100 past incidents across campus zones) — `npm run seed:demo`
- [x] Unit tests: models, `IncidentStatus.canTransition`, validators
- [x] Widget tests: register, SOS countdown, report form
- [x] Rules tests passing for all collections
- [ ] Alpha test with classmates; beta with security officers — record SOS latency and task times for Chapter 6 (protocol and record sheets: `docs/TESTING.md`)
- [ ] Fix issues; accessibility pass (font scaling, contrast) — accessibility pass done (D49); fix what alpha/beta finds
- [x] Build release APK; deploy rules, API (Vercel), hosting; per-minute sweep on cron-job.org (SETUP §8, D52)
- [x] Write user manual (student/officer) and admin manual for Chapter 7 — `docs/USER_MANUAL.md`, `docs/ADMIN_MANUAL.md`
- [ ] Screenshots of every screen for the thesis

## Test checklist for Chapter 6

| Test | Target | Result |
| --- | --- | --- |
| SOS to officer notification (4G) | ≤ 5 s | |
| SOS with no data → SMS/call fallback offered | yes | |
| Fake ID registration rejected | yes | |
| Student cannot read another student's incident | denied | |
| Officer location view updates while victim moves | every 5–10 s | |
| Report with 3 photos submits | ≤ 15 s on 4G | |
| Dashboard live with 50 concurrent users | no lag | |
| First-time user files a report | < 60 s | |
