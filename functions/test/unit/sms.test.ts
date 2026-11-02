import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { contactNumbers, MAX_CONTACTS, sosSmsText } from "../../src/sms/messages";

describe("emergency contact SMS", () => {
  it("texts valid, distinct Ghana numbers only, at most five", () => {
    const contacts = [
      { phone: "+233241234567" },
      { phone: "+233241234567" },
      { phone: "0241234567" },
      {},
      ...Array.from({ length: 6 }, (_, i) => ({ phone: `+23320000000${i}` })),
    ];
    const numbers = contactNumbers(contacts);
    assert.equal(numbers.length, MAX_CONTACTS);
    assert.equal(numbers[0], "+233241234567");
    assert.ok(!numbers.includes("0241234567"));
  });

  it("includes a Google Maps link when the location is known", () => {
    const text = sosSmsText("Kwame Mensah", { latitude: 5.793, longitude: -0.122 });
    assert.match(text, /Kwame Mensah has pressed SOS/);
    assert.match(text, /https:\/\/maps\.google\.com\/\?q=5\.793000,-0\.122000/);
    assert.match(sosSmsText("Kwame Mensah", null), /not known yet/);
  });
});
