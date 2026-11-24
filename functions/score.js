// Recompute from the immutable ledger; never increment a client-supplied balance.
function adultScore(uid, profile, entries, revokedShiftIds) {
  if (!profile || typeof profile.name !== "string" || !profile.name.trim()) {
    return null;
  }
  const completed = new Set();
  for (const entry of entries) {
    if (entry.ownerUid === uid && entry.participantId === "parent" &&
        entry.status === "confirmed" && typeof entry.shiftId === "string" &&
        !revokedShiftIds.has(entry.shiftId)) {
      completed.add(entry.shiftId);
    }
  }
  if (!completed.size) return null;
  return {
    displayName: profile.name.trim().split(/\s+/u)[0].slice(0, 80),
    points: completed.size * 100,
  };
}

module.exports = { adultScore };
