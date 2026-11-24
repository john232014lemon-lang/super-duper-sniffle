const { initializeApp } = require("firebase-admin/app");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { refreshAdult } = require("./leaderboard");

initializeApp();
const options = { region: "us-south1", database: "(default)", retry: true, maxInstances: 3 };

exports.leaderboardAttendance = onDocumentWritten({
  ...options,
  document: "attendance/{sid}/families/{uid}/attendanceEntries/{pid}",
}, (event) => event.params.pid === "parent" ? refreshAdult(event.params.uid) : undefined);

exports.leaderboardRevocation = onDocumentWritten({
  ...options,
  document: "attendanceRevocations/{sid}/revokedFamilies/{uid}",
}, (event) => refreshAdult(event.params.uid));

exports.leaderboardProfile = onDocumentWritten({
  ...options,
  document: "profiles/{uid}",
}, (event) => refreshAdult(event.params.uid));
