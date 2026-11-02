# Testing guide — VVU Campus Safety

How the system is tested, and how to run the alpha (classmates) and beta
(security officers) tests whose results go into thesis Chapter 6.

## 1. Automated tests

Run these before every test session and before each deploy.

| Suite | Command | What it covers |
| --- | --- | --- |
| Flutter unit and widget tests | `flutter test` | Models and their Firestore maps, the incident state machine, validators and phone/ID normalisation, routing by role, dashboard statistics, the CSV export and parsers, colour contrast. Widget tests for registration, the SOS countdown and the report form, plus 200% text on the SOS screens. |
| Static analysis | `flutter analyze` | Lints from `analysis_options.yaml`. |
| Cloud Functions unit tests | `cd functions && npm test` | ID verification, incident triggers, chat and announcement pushes, admin input checks, settings, SMS text, backup paths. |
| Security rules tests | `cd functions && npm run test:rules` | Every collection: who can read and write users, contacts, the roster, incidents (with locations, events and chat), announcements, settings and the audit log, and the photo rules in Storage. Includes "a student cannot read another student's incident". |
| Functions lint and build | `cd functions && npm run lint && npm run build` | TypeScript errors and style. |

`npm run test:rules` starts its own emulators. If the dev emulators are
already running, use `npm run test:rules:run` instead; it uses a separate
project (`demo-vvu-rules-test`), so your demo data is untouched.

## 2. Before a test session

1. Deploy (SETUP.md §8), or run the emulators with your PC and phones on
   the same Wi-Fi (`--dart-define=EMULATOR_HOST=<PC IP>`). Push
   notifications need the real project.
2. Import the testers' IDs on the dashboard's **ID roster** page, or use
   the sample IDs in `functions/scripts/seedRoster.ts`.
3. Create officer accounts on the **Users** page and have each officer
   sign in on their phone and switch **On duty** on.
4. For the analytics part, load past data: `cd functions && npm run seed:demo`
   (emulator only).
5. Print one copy of the record sheets in §4 per tester.

## 3. Scenarios

Ask testers to think aloud, and note what confuses them. Don't help unless
they are stuck for more than a minute; note that you helped.

**Students and staff (alpha)**

| # | Task | Done when |
| --- | --- | --- |
| A1 | Install the app, register with your VVU ID and sign in. | The SOS screen shows. |
| A2 | Try to register with a made-up ID. | The app refuses with "ID not found". |
| A3 | Add an emergency contact. | The contact is listed. |
| A4 | Report a theft with two photos, starting from the home screen. | "Report sent" shows. Time it (target < 60 s for a first-time user). |
| A5 | Press SOS and let the countdown finish. | "Security has been alerted", then "<officer> is on the way" when an officer accepts. |
| A6 | Press SOS, then cancel during the countdown. | Nothing is sent. |
| A7 | Send a message to security from your report. | The officer replies and you see it. |
| A8 | With mobile data and Wi-Fi off, press SOS. | The "No connection yet" card offers "Call security" and "Text security my location"; the alert sends by itself once back online. |

**Security officers (beta)**

| # | Task | Done when |
| --- | --- | --- |
| B1 | Go on duty. Wait for an SOS from the tester. | The alert sounds on your phone. |
| B2 | Accept, open directions, mark "on scene", resolve with a note. | The student sees each status change. |
| B3 | While the student walks about 100 m, watch their dot on the map. | It moves every 5–10 s. |
| B4 | Assign a colleague to an incident and add a note. | The colleague sees it in their list. |
| B5 | Mark a test alert as a false alarm. | It leaves the queue. |

**Chief Security Officer (dashboard)**

| # | Task | Done when |
| --- | --- | --- |
| C1 | Watch the live board while a tester sends an SOS. | The banner flashes and beeps, and the marker appears. |
| C2 | Find last week's thefts and export them to CSV. | The file opens in Excel. |
| C3 | Add an officer, then deactivate a test account. | The deactivated user is signed out. |
| C4 | Post an announcement to students. | Students receive it. |
| C5 | Change the SOS countdown to 5 s in Settings. | New SOS countdowns last 5 s; the change is in the audit log. |

## 4. Measurements for Chapter 6

### SOS latency (target ≤ 5 s on 4G)

Two phones on 4G, no Wi-Fi: phone A signed in as a student, phone B as an
on-duty officer. Set the countdown to 0 s in Settings for this test (put it
back afterwards).

1. Start a stopwatch the moment you press SOS on phone A.
2. Stop it when phone B sounds.
3. Open the incident on the dashboard: the timeline's `created` and
   `alerted` times give the server's share of the delay.
4. Repeat 10 times at different places on campus. Report the median and
   the slowest.

| Run | Place | Stopwatch (s) | created → alerted (s) | Notes |
| --- | --- | --- | --- | --- |
| 1 | | | | |
| … | | | | |

### Other checks

| Test | Target | How | Result |
| --- | --- | --- | --- |
| SOS with no data → SMS/call fallback offered | yes | A8 | |
| Fake ID registration rejected | yes | A2 | |
| Student cannot read another student's incident | denied | Rules test "stops another student reading it" (run `npm run test:rules`), and in the app: one student's report never appears under another's My reports | |
| Officer location view updates while victim moves | every 5–10 s | B3: count the seconds between dot moves | |
| Report with 3 photos submits | ≤ 15 s on 4G | Time from tapping Send to "Report sent" | |
| Dashboard live with 50 concurrent users | no lag | Ask 50 people (a class) to open the dashboard login with test admin accounts, or open it on many devices, while SOS alerts are sent; note any delay on the live board | |
| First-time user files a report | < 60 s | A4 | |

### Task times and satisfaction

Record each tester's time for A1, A4 and A5 and whether they finished
without help. After the session, ask them to rate from 1 (strongly
disagree) to 5 (strongly agree):

1. I could send an SOS quickly without thinking about it.
2. I understood what was happening after I pressed SOS.
3. Reporting an incident was easy.
4. I would trust this app in a real emergency.
5. I would recommend it to other students.

Officers and the CSO also answer: "The app shows me what I need to respond."
