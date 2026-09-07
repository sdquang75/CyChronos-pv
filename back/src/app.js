const express = require("express");
const cors = require("cors");
const path = require("path");
require("dotenv").config();

const { requireAppUser, optionalAppUser } = require("./middleware/auth");
const pool = require("./db");
const tripsRouter = require("./routes/trips");
const locationsRouter = require("./routes/locations");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({ message: "CyChronos API is running" });
});

app.use("/api/auth", require("./routes/auth"));
app.use("/api/maps", require("./routes/maps"));
// 提案は未ログインでも使える。ログイン済みなら訪問済みスポットを除外する
app.use("/api/suggest", optionalAppUser, require("./routes/suggest"));
// 走行データは本人のものしか触らせない(user_id は検証済みトークンから引く)
app.use("/api/trips", requireAppUser, tripsRouter);
app.use("/api/locations", requireAppUser, locationsRouter);
app.use("/api/settings", requireAppUser, require("./routes/settings"));

// 単体テスト用の簡易フロント(http://localhost:3000/test/)。
// 認証なしでAPIを叩ける画面なので、本番では配信しない
if (process.env.NODE_ENV !== "production") {
  app.use("/test", express.static(path.join(__dirname, "../test-front")));
}

app.use((req, res) => {
  res.status(404).json({ error: "Not Found" });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: "Internal Server Error" });
});

async function initDatabase() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS \`user_settings\` (
        \`user_id\` bigint unsigned NOT NULL,
        \`include_visited_places\` tinyint(1) NOT NULL DEFAULT '0',
        \`voice_guidance_enabled\` tinyint(1) NOT NULL DEFAULT '1',
        \`keep_screen_awake\` tinyint(1) NOT NULL DEFAULT '1',
        \`auto_reroute_enabled\` tinyint(1) NOT NULL DEFAULT '1',
        \`map_type\` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'normal',
        \`updated_at\` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (\`user_id\`),
        CONSTRAINT \`fk_user_settings_user\` FOREIGN KEY (\`user_id\`) REFERENCES \`users\` (\`user_id\`) ON DELETE CASCADE ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);
    console.log("Database initialized: user_settings table ready.");
  } catch (err) {
    console.warn("Database auto-migration note:", err.message);
  }
}

const port = process.env.PORT || 3000;

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
  initDatabase();
});
