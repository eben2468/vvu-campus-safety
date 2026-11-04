# Setup — VVU Campus Safety App

## 1. Tools to install

| Tool | Check | Notes |
| --- | --- | --- |
| Flutter SDK (stable) | `flutter doctor` | Includes Dart |
| Android Studio | — | For Android SDK, emulator, platform tools (you'll code in VS Code) |
| Node.js LTS | `node -v` | For the Firebase CLI and the server API |
| Firebase CLI | `firebase --version` | `npm install -g firebase-tools` |
| FlutterFire CLI | `flutterfire --version` | `dart pub global activate flutterfire_cli` |
| Vercel CLI | `vercel --version` | `npm install -g vercel`, to deploy the API |
| Java JDK 17+ | `java -version` | Needed by the Firestore emulator |
| Git | `git --version` | |

VS Code extensions: **Flutter**, **Dart**, **Claude Code**, **Firebase Explorer** (optional), **Error Lens** (optional).

Run `flutter doctor` until Android toolchain and Chrome show green ticks. Accept licences with `flutter doctor --android-licenses`.

## 2. Create the project

```bash
flutter create --org gh.edu.vvu --platforms=android,web vvu_campus_safety
cd vvu_campus_safety
# copy CLAUDE.md and docs/ from this pack into the project root
git init && git add . && git commit -m "Initial project + docs"
```

Then open the folder in VS Code and start Claude Code in it — it picks up `CLAUDE.md` automatically.

## 3. Firebase project (free Spark plan, no card)

1. Go to the Firebase console → **Add project** → name it `VVU Campus Safety` and note the **project ID**. Google Analytics isn't needed.
2. **Stay on the Spark plan.** Don't enable Storage or Functions: the API on Vercel does those jobs (DECISIONS D52).
3. Enable products:
   - Authentication → Email/Password
   - Firestore Database → production mode, location close to Ghana (e.g. `europe-west1`)
   - Cloud Messaging and Hosting need no setup
4. Connect the app:

```bash
firebase login
flutterfire configure --project=<project-id> --platforms=android,web
```

5. **Project settings → Service accounts → Generate new private key.** Save the JSON file **outside the project folder**: it gives full access and must never be committed. Step 8 puts it in Vercel.

## 4. Maps

Nothing to set up. The in-app maps use OpenStreetMap tiles through `flutter_map` (DECISIONS D50): no API key, no billing account. They need an internet connection to load tiles. The officer's **Go** button and SMS location links open Google Maps by plain URL, which also needs no key.

## 5. Android configuration

- `minSdkVersion` 23 or higher (Firebase requirement) in `android/app/build.gradle`.
- Permissions in `AndroidManifest.xml`: `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`, `CAMERA`, `CALL_PHONE` (optional — or use the dialer intent without it).
- Keep the `firebase_messaging_installation_id_enabled` meta-data in `AndroidManifest.xml`: without it `register()` fails with "API disabled" and the device gets no pushes.
- Create notification channels `sos_alarm` and `sos_alerts` (max importance) at app start. The alarm is `res/raw/sos_alarm.wav`, made by `dart run tool/make_alarm_sound.dart`; `res/raw/keep.xml` stops the release build removing it. Android fixes a channel's sound when it is created, so a new sound needs a new channel id.

## 6. Run locally with emulators

The `.firebaserc` default project is `demo-vvu-campus-safety`, an emulator-only
project that needs no login, and the committed `lib/firebase_options.dart` points at
it. So you can run everything locally before steps 3–4 are done. After
`flutterfire configure`, use `firebase use prod` (or `--project prod`) for deploys.

```bash
firebase emulators:start --import=./emulator-data --export-on-exit
# in another terminal: the API, on port 3000
cd functions && npm run api:dev
# seed sample roster + settings
cd functions && npm run seed   # sample IDs are listed in functions/scripts/seedRoster.ts
# optional: 120 past incidents over 12 weeks for the analytics demo
cd functions && npm run seed:demo
# run the app
flutter run -d <android-device> --dart-define=USE_EMULATOR=true
flutter run -d chrome --web-port 5000 --dart-define=USE_EMULATOR=true
```

Android emulator reaches your machine's emulators at `10.0.2.2` (the default in `main.dart`). Emulator UI: http://localhost:4000. Hosting emulator: port 5002 (5000 is used by `flutter run -d chrome`).

A physical phone has two options:

- **USB (no shared Wi-Fi needed):** enable USB debugging, forward the ports, then run with `127.0.0.1`:

  ```bash
  for p in 9099 8080 3000; do adb reverse tcp:$p tcp:$p; done
  flutter run -d <phone-id> --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=127.0.0.1
  ```

  The forwarding is lost whenever the USB connection resets; run the `adb reverse` lines again if sign-in suddenly says "No internet connection".
- **Same Wi-Fi:** `--dart-define=EMULATOR_HOST=<PC LAN IP>`, with the emulators listening on all interfaces (`"host": "0.0.0.0"` per emulator in `firebase.json`) and the ports allowed through the firewall.

Note: FCM push doesn't fully work in the emulator — test push notifications against the real project with a physical phone.

## 7. First admin account

Self sign-up never creates admins. Bootstrap one with a one-off script run against the real project, using the key from §3 (it stays on your PC):

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\keys\service-account.json"
cd functions
npm run make-admin -- <project-id> cso@vvu.edu.gh "Full Name" +233XXXXXXXXX "temporary-password"
```

`functions/scripts/makeAdmin.ts` sets custom claims `{ role: 'admin', verified: true }` and creates the `users` doc. If the email already has an account it is promoted and the password is ignored. After that, create officers from the dashboard.

## 8. Deploy

**The API, on Vercel** (free Hobby plan):

1. Push the repo to GitHub and sign up at vercel.com.
2. **Add New → Project**, import the repo, and set **Root Directory** to `functions`. Pushing to `main` then deploys the API by itself.
3. In the Vercel dashboard: **Storage → Create Database → Blob**, with access set to **Private**, connected to the project for Production. A store's access can't be changed later, and the server reads and writes it as private. This adds `BLOB_STORE_ID`, and the server signs in with Vercel's OIDC token, so no token needs copying.
4. **Settings → Environment Variables**, for Production:

| Name | Value |
| --- | --- |
| `FIREBASE_SERVICE_ACCOUNT` | The whole JSON key file from §3, pasted as one value |
| `CRON_SECRET` | A long random string you make up |
| `BACKUP_KEY` | Another long random string. **Keep a copy**: without it backups can't be opened |

5. **Deployments → ⋯ → Redeploy**, because variables only reach new deployments. Note the address, e.g. `https://vvu-safety.vercel.app`.
6. Open `https://<your-project>.vercel.app/api/health`. It shows no secrets, only whether each setting arrived: `serviceAccountSet`, `blobConnected`, `cronSecretSet` and `backupKeySet` should all be true.

If saved variables still don't reach the running server, and sign-in fails with "Your session has expired", create a fresh Vercel project from the same repo and add them again. That fixed it for this project.

`functions/package.json` pins `jwks-rsa` to 3.2.2 with an override: version 4 needs an ES-module-only library that crashes the function on Vercel.

On Windows, `npm.cmd` adds `^` to quoted arguments containing spaces, so check the name after `npm run make-admin`.

**The safety-net sweep.** Vercel's free cron only runs daily, so sign up at cron-job.org (free) and create a job:

- URL: `https://<your-project>.vercel.app/api/sweep`
- Every 1 minute, method GET
- Header `Authorization` with value `Bearer <your CRON_SECRET>`

The job's history should show **200 OK** each minute; 403 means the header is wrong.

**Firestore rules, the dashboard and the app**, using your API address:

```bash
firebase use prod
flutter build web --release --dart-define=API_URL=https://<your-project>.vercel.app/api
firebase deploy --only firestore:rules,firestore:indexes,hosting
flutter build apk --release --dart-define=API_URL=https://<your-project>.vercel.app/api
```

**Backups.** `vercel.json` runs `/api/backup` daily at 02:00. It saves `backups/YYYY-MM-DD.json.gz.enc` to Blob, encrypted with `BACKUP_KEY`, and skips itself above 20,000 documents so that it can't use up the free daily reads. To restore one, download the file from the Blob store, then:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\keys\service-account.json"
$env:BACKUP_KEY = "<your BACKUP_KEY>"
cd functions
npm run restore-backup -- <project-id> <backup file>
```

**Free-plan limits to keep an eye on:** Firestore 50,000 reads and 20,000 writes a day (the app stops working for the rest of the day if they run out); Vercel Blob about 1 GB; Vercel's Hobby plan is for personal, non-commercial use, which suits this project but not a paid roll-out.

Emergency-contact SMS uses `ConsoleSmsProvider` (logs only) until a gateway
is chosen (DECISIONS O2). To add one, implement `SmsProvider` in
`functions/src/sms/`, store its key as a Vercel environment variable,
and return it from `getSmsProvider()`.

## 9. Data you need from VVU

- ID roster CSV from Registry/HR: `idNumber,fullName,type,department`
- Security Office emergency phone number
- Campus boundary + key zones (main gate, hostels, lecture halls, admin block, church, sports field) — can be traced in Google Maps and saved as coordinates in `settings/app`
- List of on-duty officers to create accounts for
