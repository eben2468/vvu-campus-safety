# VVU Campus Safety — Admin manual

For the Chief Security Officer and supervisors using the web dashboard.
Open the dashboard address in Chrome or Edge on a computer and sign in
with your admin account. Students, staff and officers who open the web
address are told to use the phone app; only admins can use the dashboard.

On a phone, an admin account opens the officer screens, so you can also
accept and handle alerts in the field (User manual, Part B).

The dark menu on the left has eight pages in three groups:
**Operations** (Live board, Incidents, Analytics), **People** (Users,
ID roster, Announcements) and **System** (Settings, Audit log). Your name
and the **sign out** button are at the bottom of the menu. On a narrower
window the menu shows icons only; point at one to see its name. A red
**New SOS** banner appears at the top of any page when an SOS arrives
(see §1).

## 1. Live board

The page to keep open in the Security Office.

- **Summary cards:** incidents open now, today's total, the average
  response time (raised → accepted) today and over 7 days, and the
  incidents resolved today.
- **Campus map:** every open incident with a known location; red markers
  are SOS alerts, blue are reports. Point at a pin to see who raised it;
  click it to open the incident.
- **Open incidents:** the same incidents as a list, SOS first.
- **Recent activity:** the latest updates from every incident. Click one
  to open its incident.

**New SOS alarm.** When an SOS arrives that nobody has accepted, the
dashboard beeps three times and a red banner flashes on whatever page is
open. Click **View** to open the SOS, or **Dismiss** to silence it. The
banner also clears by itself once an officer accepts. The browser only
plays sound after you have clicked somewhere on the page, which signing
in does; keep the computer's volume up.

## 2. Incidents

The 300 most recent incidents in a table. Narrow the list by:

- **Open**, **Closed** or **All**;
- type (SOS or reports) and category;
- search: reporter name, place or status.

Click a row to open the **incident panel** on the right:

- **Details:** map, reporter and phone, place, times, response time,
  assigned officers, description and photos, and the timeline. Below the
  facts are the same response buttons officers have (accept, on scene,
  resolve, assign, add note, false alarm). As an admin you can resolve any
  open incident.
- **Chat:** the conversation with the reporter. Messages you send are
  labelled as from security.

Close the panel with **X** or by clicking outside it.

## 3. Analytics

- Choose a **date range** (default: the last 30 days) and a **category**
  (or "SOS alerts").
- The **map** shows where incidents happened: each circle covers about
  50 m, and bigger, redder circles mean more incidents. The number on each
  circle is how many incidents happened there.
- **Totals** at the top: incidents, SOS alerts, average response time and
  false alarms for the chosen period.
- **Charts:** incidents by category, incidents per week (weeks start on
  Monday), and the average response time per week.
- **Export CSV** (top right) downloads exactly the incidents shown, for Excel or
  reports. Times are Ghana time.

## 4. Users

Lists users by group: **Security team** (officers and admins),
**Students**, **Staff** or **Everyone**. Search by name, email, phone or
VVU ID. The status column shows Deactivated, On duty, or how many false
alarms a user has raised.

- **Add officer or admin:** enter the name, email, Ghana phone number and
  a temporary password (at least 8 characters), and choose Officer or
  Admin. Give the person their email and temporary password; they should
  change it with **Forgot password?** on the log-in screen.
- **⋮ → Change role…:** for example, make a staff member an officer. The
  change applies to their app within seconds.
- **⋮ → Deactivate…:** signs the person out straight away and stops them
  signing in, raising alerts or receiving them. Their past incidents stay
  on record. **Reactivate** undoes it.

You can't change your own role or deactivate yourself; ask another admin.

## 5. ID roster

Students and staff can only register with an ID on the roster.

The **Imported IDs** tab lists every ID on the roster, with its type,
department and status: **Not registered**, **Registered** or **Blocked**.
Search by ID, name or department, or filter by status. The list updates by
itself as people register. It shows the first 2,000 IDs; every imported ID
can still register. People appear under **Users** only once they have
registered.

To add IDs, open the **Import a file** tab:

1. Click **Download sample CSV** and open the file in Excel or Google
   Sheets. It has the right columns and six example rows.
2. Replace the example rows with the list from the Registry (students) or
   HR (staff), one person per row, keeping the header row. The columns are
   `idNumber,fullName,type,department,active`: type is `student` or
   `staff`; `active` set to `false` blocks an ID (for example a student who
   has left). The page lists each column and whether it is required.
3. Save as CSV (comma separated), then click **Choose CSV file**. The
   preview shows the first rows and lists any lines it will skip and why.
4. Click **Import**. The result shows how many IDs were imported and which
   rows were rejected.

Importing an updated list each semester is safe: existing IDs are updated
and stay linked to the accounts already registered with them.

## 6. Announcements

Write a title and message, choose who receives it (**Everyone**,
**Students**, **Staff** or **Officers**) and click **Send announcement**.
Everyone in that group gets a notification, and it appears in their
announcement list. Sent announcements are listed on the right.

## 7. Settings

- **Report categories:** add or remove the choices on the report form.
  Removing one doesn't change existing reports.
- **Security Office emergency number:** used by every **Call security**
  button and the offline text. Use the +233 format.
- **SOS countdown:** seconds a user has to cancel after pressing SOS
  (0–10; 0 sends at once).
- **Campus boundary:** one `latitude, longitude` per line, going round the
  campus. To get a point, right-click the spot in Google Maps and click
  the coordinates to copy them.
- **Campus zones:** one `name, latitude, longitude, radius in metres` per
  line, e.g. `Hostels, 5.795, -0.124, 150`. Incidents inside a zone are
  labelled with its name ("near Hostels").

Click **Save settings** (top right). Errors name the line to fix. Every change is
recorded in the audit log.

## 8. Audit log

A read-only record of every admin action: accounts created, role changes,
deactivations, roster imports and settings changes, with who did it and
when. The 200 most recent are shown. Nobody can edit or delete entries.

## 9. Backups and privacy

- The database is backed up automatically every night at 02:00, encrypted.
  To restore one, ask the system administrator (SETUP.md §8).
- Students' emergency contacts are private: not even admins can see them
  in the dashboard.
- Incidents are never deleted, so the record is complete for
  investigations.
