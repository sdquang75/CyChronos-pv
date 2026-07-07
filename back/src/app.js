const express = require("express");
const cors = require("cors");
const path = require("path");
require("dotenv").config();

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
app.use("/api/suggest", require("./routes/suggest"));
app.use("/api/trips", tripsRouter);
app.use("/api/locations", locationsRouter);

// 単体テスト用の簡易フロント(http://localhost:3000/test/)
app.use("/test", express.static(path.join(__dirname, "../test-front")));

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

