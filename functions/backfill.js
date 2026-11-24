// Developer-run only, after publishing functions, rules, and existing indexes.
const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { refreshAdult } = require("./leaderboard");

const projectId = "bushel-volunteer-20260925";
if (process.env.GOOGLE_CLOUD_PROJECT !== projectId || !process.argv.includes("--apply")) {
  throw new Error(`Set GOOGLE_CLOUD_PROJECT=${projectId} and pass --apply to rebuild the leaderboard.`);
}
initializeApp({ credential: applicationDefault(), projectId });

async function main() {
  const db = getFirestore();
  const status = db.doc("leaderboardStatus/current");
  await status.set({ ready: false });
  const profiles = await db.collection("profiles").select().get();
  const existing = await db.collection("leaderboard").select().get();
  const ids = new Set([...profiles.docs, ...existing.docs].map((doc) => doc.id));
  for (const uid of ids) await refreshAdult(uid);
  await status.set({ ready: true });
  console.log(`Rebuilt leaderboard for ${ids.size} adult accounts in ${projectId}.`);
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
