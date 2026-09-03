const express = require("express");
const cors = require("cors");
const path = require("path");
require("dotenv").config();

const { requireAppUser, optionalAppUser } = require("./middleware/auth");
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

const port = process.env.PORT || 3000;

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
