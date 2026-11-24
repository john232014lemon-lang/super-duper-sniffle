const { getFirestore } = require("firebase-admin/firestore");
const { adultScore } = require("./score");

async function refreshAdult(uid) {
  const db = getFirestore();
  const target = db.collection("leaderboard").doc(uid);
  // Read current state in a transaction, rather than applying event deltas:
  // duplicate/out-of-order triggers and simultaneous revocations are safe.
  await db.runTransaction(async (tx) => {
    const profile = await tx.get(db.collection("profiles").doc(uid));
    const entries = await tx.get(
      db.collectionGroup("attendanceEntries").where("ownerUid", "==", uid),
    );
    const revoked = await tx.get(
      db.collectionGroup("revokedFamilies").where("ownerUid", "==", uid),
    );
    const canonicalEntries = entries.docs.filter((doc) => {
      const data = doc.data();
      return data.participantId === "parent" &&
        doc.ref.path === `attendance/${data.shiftId}/families/${uid}/attendanceEntries/parent`;
    }).map((doc) => doc.data());
    const revokedIds = new Set(revoked.docs.filter((doc) =>
      doc.ref.path === `attendanceRevocations/${doc.data().shiftId}/revokedFamilies/${uid}`,
    ).map((doc) => doc.data().shiftId));
    const score = adultScore(uid, profile.data(), canonicalEntries, revokedIds);
    if (score) tx.set(target, score);
    else tx.delete(target);
  });
}

module.exports = { refreshAdult };
