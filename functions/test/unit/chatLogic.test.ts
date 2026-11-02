import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { announcementPush, isAudience, messageAudience, messagePush, preview } from "../../src/chatLogic";
import { IncidentDoc } from "../../src/incidentLogic";

const incident: IncidentDoc = {
  kind: "report",
  category: "Theft",
  status: "accepted",
  reporterId: "kwame",
  reporterName: "Kwame Mensah",
  assignedTo: ["officer1"],
};

describe("messageAudience", () => {
  it("sends the reporter's messages to security", () => {
    assert.equal(messageAudience("kwame", incident), "security");
  });

  it("sends security's messages to the reporter", () => {
    assert.equal(messageAudience("officer1", incident), "reporter");
    assert.equal(messageAudience("admin1", incident), "reporter");
  });
});

describe("messagePush", () => {
  it("labels messages from security", () => {
    assert.deepEqual(messagePush("Test Officer", "On my way", false, true), {
      title: "Security: Test Officer",
      body: "On my way",
    });
  });

  it("describes a photo-only message", () => {
    assert.equal(messagePush("Kwame Mensah", "  ", true, false).body, "Sent a photo.");
    assert.equal(messagePush("Kwame Mensah", "", true, false).title, "Message from Kwame Mensah");
  });
});

describe("preview", () => {
  it("leaves short text alone and tidies spaces", () => {
    assert.equal(preview("  Gate  closed \n tonight "), "Gate closed tonight");
  });

  it("cuts long text at a word boundary", () => {
    const text = "The main gate will close early tonight because of maintenance work on the road";
    const short = preview(text, 40);
    assert.ok(short.length <= 40);
    assert.ok(short.endsWith("…"));
    assert.ok(!short.includes("mainte"), short);
  });
});

describe("announcements", () => {
  it("accepts only the four audiences", () => {
    for (const a of ["all", "students", "staff", "officers"]) assert.ok(isAudience(a));
    assert.equal(isAudience("admins"), false);
    assert.equal(isAudience(undefined), false);
  });

  it("builds the push from title and body", () => {
    assert.deepEqual(announcementPush("Night escort", "Officers escort students after 10 pm."), {
      title: "Night escort",
      body: "Officers escort students after 10 pm.",
    });
  });
});
