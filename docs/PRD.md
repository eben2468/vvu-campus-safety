# Product Requirements — VVU Campus Safety App

Source: project proposal by Ezekiel Agoe Kumah (223IT0100946), supervisor Gifty Tanoah Peprah, VVU Department of IT, dated 10/06/2026. Section references (e.g. 4.2.2) point to that proposal.

## 1. Problem

VVU Oyibi campus security relies on phone calls, verbal reports, logbooks and physical patrols. Victims can't always explain where they are, security gets incomplete information, and there's no central record for spotting high-risk areas. Recent non-natural student deaths and assaults on Ghanaian campuses (Joy News Research, 2026) underline the need for faster response.

## 2. Objectives (proposal 1.2)

- **General:** design and implement a mobile app that improves campus security and emergency response.
- **Obj i:** real-time GPS location sharing during emergencies.
- **Obj ii:** direct communication between students and campus security.
- **Obj iii:** image-based incident reporting.
- **Obj iv:** incident tracking and heatmap analytics for campus authorities.

Plus student/staff ID authentication (Ch1) so only authorised people can use the system.

## 3. Users and roles

| Role | Platform | Summary |
| --- | --- | --- |
| `student` | Mobile | Verified by student ID. Raises SOS, reports incidents, chats, manages emergency contacts. |
| `staff` | Mobile | Same as student, verified by staff ID. |
| `officer` | Mobile | Security personnel. Goes on/off duty, receives alerts, accepts/assigns, navigates, updates status, resolves. |
| `admin` | Web | Chief Security Officer / supervisors. Live board, incident management, users, announcements, analytics, settings, audit log. |

Visitors are **not** users in the MVP (see `DECISIONS.md`).

## 4. Features, user stories and acceptance criteria

Priority: **M** = Must (MVP, maps to objectives), **S** = Should (MVP if time allows), **L** = Later.

### 4.1 Registration and authentication (4.2.1) — M

Stories
- As a student/staff member, I register with my VVU ID so only real members of the university can use the app.
- As a user, I log in, reset a forgotten password and change my password.

Acceptance criteria
- Register form: full name, ID number, email, phone (+233), password (min 8 chars), confirm password.
- On submit, a callable Cloud Function `verifyId` checks the ID number against `idRoster`: it must exist, be `active`, and not already `claimedBy` another account. Name match is case-insensitive on surname.
- Success → `users/{uid}` created with `verified: true`, custom claim `role` set to the roster `type` (`student`/`staff`), roster entry marked `claimedBy: uid`.
- Failure → clear message ("ID not found — contact Security Office") and no usable account.
- Email verification link sent; unverified emails can log in but see a banner.
- Forgot password uses Firebase password-reset email.
- Officers and admins are created by an admin from the dashboard, not via self sign-up.
- Deactivated users are signed out and blocked by security rules.

### 4.2 Emergency SOS (4.2.2, Obj i) — M

Stories
- As a user in danger, I press one button and security is alerted with my exact location without typing anything.

Acceptance criteria
- SOS button is the dominant element of the home screen.
- Press → 3-second countdown with large **Cancel**; after countdown the alert is sent. (Countdown length from `settings/app.sosCountdownSec`.)
- On send: an `incidents` doc is created with `kind: 'sos'`, `status: 'new'`, current GPS location, `reporterId`.
- Cloud Function trigger moves it to `alerted` and pushes a high-priority notification to **all on-duty officers** (and admins with dashboard open via Firestore listener).
- While SOS is active, the device writes location to `incidents/{id}/locations` every 5–10 s (or on 10 m movement) until status is `resolved` or `false_alarm`.
- Active SOS screen shows: "Alert sent", officer name once accepted, chat button, call-security button, a hold-to-cancel control ("I'm safe").
- If there is no data connection: the write is queued (Firestore offline) **and** the app offers a one-tap SMS/call to the security emergency number from settings.
- A user can have only one active SOS at a time.
- Alert must reach an officer device within 5 s on 4G (test target).

### 4.3 Incident reporting (4.2.3, Obj iii) — M

Stories
- As a user, I report a non-urgent incident (theft, harassment, fire, accident, medical, suspicious activity, other) with photos and a location.

Acceptance criteria
- Form: category (from `settings/app.categories`), description (10–1000 chars), up to 3 photos (camera or gallery, compressed to ≤ 1 MB each), location (auto GPS, adjustable pin on map), optional "report anonymously to other students" is **not** offered — security always sees the reporter.
- Photos upload to Storage `incidents/{incidentId}/…` and URLs saved in `mediaUrls`.
- Submit creates `incidents` doc with `kind: 'report'`; on-duty officers are notified.
- "My reports" lists the user's incidents, newest first, with status chips.
- Incident detail shows description, photos, map pin and a status timeline from `events`.

### 4.4 Live location tracking (4.2.4, Obj i) — M

Acceptance criteria
- Officer's alert detail shows the reporter's latest location on a map, updating live.
- "Navigate" opens Google Maps directions to that point (`url_launcher`).
- Location updates stop automatically when the incident closes.
- Location is only collected during an active SOS — never in the background otherwise.

### 4.5 Officer response and incident management (4.2.7) — M

Acceptance criteria
- Officer home: on-duty toggle; live queue of `new`/`alerted`/`accepted`/`on_scene` incidents, SOS first, then oldest first.
- Officer can: **Accept** (sets `accepted`, adds self to `assignedTo`, sets `acknowledgedAt`), **Assign** to other officers, **Mark on scene**, **Add note**, **Resolve**, **Mark false alarm**.
- Each action writes an `events` entry (actor, type, text, timestamp) and the reporter gets a push update.
- Admins can do all of the above from the dashboard.

### 4.6 Direct communication (Obj ii) — M

Acceptance criteria
- Each incident has a chat (`incidents/{id}/messages`) between the reporter and assigned officers/admins, real-time, text plus optional photo.
- "Call security" button on home and incident screens dials the number in `settings/app.securityPhone`.

### 4.7 Notifications and announcements (4.2.6) — M

Acceptance criteria
- FCM token stored in `users/{uid}.fcmTokens` on login; removed on logout.
- Push types: new alert (officers), status update (reporter), new chat message, campus announcement (all or by audience).
- Foreground pushes shown with `flutter_local_notifications`; tapping opens the relevant screen.
- Announcements list screen in the app.

### 4.8 Security dashboard (4.2.9) — M

Acceptance criteria
- Live board: map of campus with active incidents as markers (SOS in red), list beside it, updating in real time; audible/visual cue on new SOS.
- Summary cards: active now, today's total, average response time (today/7 days), resolved today.
- Recent activity feed from `events`.

### 4.9 Heatmap analytics and reports (4.2.10, Obj iv) — M (heatmap) / S (export)

Acceptance criteria
- Heatmap of incident locations, filterable by date range and category.
- Charts: incidents per category, per week, average response time trend.
- Export the filtered incident list as CSV (S) and a printable PDF summary (L).

### 4.10 Emergency contacts (4.2.5) — S

Acceptance criteria
- Add/edit/remove up to 5 contacts (name, phone, relationship).
- On SOS, a Cloud Function sends each contact an SMS with the user's name and a Google Maps link (requires SMS gateway — see `DECISIONS.md`). Until a gateway is chosen, implement behind an `SmsProvider` interface with a console/log implementation.

### 4.11 User management (4.2.8) — S

Acceptance criteria
- Admin: list/search users, create officer/admin accounts, change role, deactivate/reactivate.
- Admin: import ID roster from CSV (columns: `idNumber,fullName,type,department`).
- All role changes go through a callable function that sets custom claims and writes `auditLogs`.

### 4.12 System administration, database, backups (4.2.11, 4.2.12) — S

Acceptance criteria
- Settings page: incident categories, security phone number, SOS countdown, campus boundary polygon.
- Audit log page (read-only) of admin actions.
- Scheduled daily Firestore export to Cloud Storage.

## 5. Screens

Mobile (student/staff)
1. Splash / onboarding (permissions explained)
2. Register → ID verification result
3. Login / Forgot password
4. Home (SOS button, Report incident, Call security, latest announcements)
5. SOS active
6. Report incident
7. My reports
8. Incident detail + chat
9. Emergency contacts
10. Announcements / notifications
11. Profile & settings

Mobile (officer)
12. Officer home (on-duty toggle, alert queue)
13. Alert detail (live map, navigate, accept/assign, chat, call)
14. Update status / notes / resolve

Web (admin)
1. Login
2. Live board
3. Incidents (table + detail drawer)
4. Analytics (heatmap + charts)
5. Reports / export
6. Users + roster import
7. Announcements
8. Settings + audit log

## 6. Non-functional requirements (4.3)

| Area | Target |
| --- | --- |
| SOS latency | Officer notified ≤ 5 s on 4G |
| SOS reach | 1 tap from home + countdown; app cold start to home ≤ 3 s on a mid-range Android |
| Location | Update every 5–10 s during active SOS only |
| Offline | SOS queued offline + SMS/call fallback |
| Security | Role-based Firestore/Storage rules; users read only their own incidents; HTTPS everywhere (Firebase default) |
| Abuse | Only verified users can raise SOS; false alarms counted per user |
| Concurrency | Dashboard stays live with 50+ simultaneous users |
| Reliability | Daily backup; incidents never hard-deleted |
| Usability | First-time user files a report in < 60 s; large touch targets; works on 5" screens |

## 7. Out of scope (Phase 2)

Visitor management, vehicle access, key register, patrol logging, shift handover (proposal Ch3 / 4.1), video evidence, iOS release, geofenced "nearest officer" routing.
