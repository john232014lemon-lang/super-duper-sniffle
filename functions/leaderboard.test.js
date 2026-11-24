const { test } = require("node:test");
const assert = require("node:assert/strict");
const { adultScore } = require("./score");

test("adult totals exclude pending, children, revoked, other owners and duplicates", () => {
  const confirmed = { ownerUid: "a", participantId: "parent", shiftId: "s1", status: "confirmed" };
  const entries = [
    confirmed, confirmed,
    { ...confirmed, shiftId: "pending", status: "pending" },
    { ...confirmed, shiftId: "child", participantId: "kid" },
    { ...confirmed, shiftId: "removed" },
    { ...confirmed, shiftId: "other", ownerUid: "b" },
  ];
  assert.deepEqual(adultScore("a", { name: "Maya Smith" }, entries, new Set(["removed"])),
    { displayName: "Maya", points: 100 });
  assert.equal(adultScore("a", { name: "Maya Smith" }, entries, new Set(["s1", "removed"])), null);
  assert.equal(adultScore("a", undefined, entries, new Set()), null);
});
