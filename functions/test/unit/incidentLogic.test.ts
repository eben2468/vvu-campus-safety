import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  alertedEventText,
  createdEventText,
  IncidentDoc,
  officerAlert,
  officerAlertChannel,
  reporterUpdate,
  statusChangeEffects,
  syncAction,
} from "../../src/incidentLogic";

describe("syncAction", () => {
  it("alerts officers about a new incident", () => {
    assert.equal(syncAction({ status: "new" }), "alert");
  });

  it("has nothing to do once a status is handled, so repeat calls are safe", () => {
    assert.equal(syncAction({ status: "alerted", handledStatus: "alerted" }), "none");
    assert.equal(syncAction({ status: "resolved", handledStatus: "resolved" }), "none");
  });

  it("applies a status the server hasn't handled yet", () => {
    assert.equal(syncAction({ status: "accepted", handledStatus: "alerted" }), "status-change");
    assert.equal(syncAction({ status: "resolved", handledStatus: "accepted" }), "status-change");
  });

  it("handles an SOS cancelled before the alert went out", () => {
    assert.equal(syncAction({ status: "resolved" }), "status-change");
  });
});

const sos: IncidentDoc = {
  kind: "sos",
  category: "emergency",
  status: "new",
  reporterId: "kwame",
  reporterName: "Kwame Mensah",
  locationLabel: "Hostels",
};

describe("event and push text", () => {
  it("describes who raised the incident", () => {
    assert.equal(createdEventText(sos), "Kwame Mensah pressed SOS.");
    assert.equal(createdEventText({ ...sos, kind: "report", category: "Theft" }), "Kwame Mensah reported: Theft.");
  });

  it("says how many officers were alerted", () => {
    assert.equal(alertedEventText(1), "Sent to 1 on-duty officer.");
    assert.equal(alertedEventText(3), "Sent to 3 on-duty officers.");
    assert.match(alertedEventText(0), /No officers are on duty/);
  });

  it("names the reporter and zone in the officer alert", () => {
    assert.deepEqual(officerAlert(sos), {
      title: "SOS — Kwame Mensah",
      body: "Emergency near Hostels. Tap to see their live location.",
    });
    assert.equal(officerAlert({ ...sos, locationLabel: null }).body, "Emergency. Tap to see their live location.");
    assert.equal(officerAlertChannel(sos).channelId, "sos_alarm");
    assert.equal(officerAlertChannel({ ...sos, kind: "report" }).channelId, "sos_alerts");
  });

  it("tells the reporter who accepted", () => {
    assert.equal(reporterUpdate("accepted", "Officer Boateng")?.body, "Officer Boateng accepted your alert and is coming.");
    assert.equal(reporterUpdate("accepted")?.body, "An officer accepted your alert and is coming.");
  });

  it("sends no reporter push for system-only statuses", () => {
    assert.equal(reporterUpdate("alerted"), null);
    assert.equal(reporterUpdate("new"), null);
  });
});

describe("statusChangeEffects", () => {
  const createdAt = new Date("2026-11-02T10:00:00Z");

  it("records the response time on first accept", () => {
    const effects = statusChangeEffects(
      { status: "alerted" },
      { status: "accepted", createdAt, acknowledgedAt: new Date("2026-11-02T10:01:30Z") },
    );
    assert.equal(effects.responseSeconds, 90);
    assert.equal(effects.deactivate, false);
  });

  it("does not overwrite an existing response time", () => {
    const effects = statusChangeEffects(
      { status: "accepted" },
      { status: "on_scene", createdAt, acknowledgedAt: new Date("2026-11-02T10:05:00Z"), responseSeconds: 90 },
    );
    assert.equal(effects.responseSeconds, undefined);
  });

  it("closes resolved incidents", () => {
    const effects = statusChangeEffects({ status: "on_scene" }, { status: "resolved", active: true });
    assert.equal(effects.deactivate, true);
    assert.equal(effects.setResolvedAt, true);
    assert.equal(effects.countFalseAlarm, false);
  });

  it("counts false alarms against the reporter", () => {
    const effects = statusChangeEffects({ status: "alerted" }, { status: "false_alarm" });
    assert.equal(effects.countFalseAlarm, true);
    assert.equal(effects.deactivate, true);
  });

  it("does not notify a reporter about their own cancel", () => {
    const effects = statusChangeEffects(
      { status: "alerted" },
      { status: "resolved", active: false, resolvedAt: new Date(), cancelledByReporter: true },
    );
    assert.equal(effects.notifyReporter, false);
    assert.equal(effects.deactivate, false);
    assert.equal(effects.setResolvedAt, false);
  });
});
