const admin = require("firebase-admin");
require("dotenv").config();

// IDトークンの検証だけならサービスアカウント鍵は不要(projectId のみで動作)
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID,
  });
}

module.exports = admin;
